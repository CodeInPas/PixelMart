unit uCustomerAI;

{$mode objfpc}{$H+}
{$INLINE ON}
{$OPTIMIZATION LEVEL3}

interface

uses
  SysUtils, Classes, fgl,  Graphics, uConstants, uGameTypes, uMathHelper, uPathfinding,
  uWorldGrid, uInventorySys, uEconomyLogic, uVisuals, uSoundManager;

type
  TCustomerAI = class
  private
    FState: TNPCState;
    FPos: TFloatPos;
    FGridPos: TGridPos;

    FGrid: TWorldGrid;
    FInventory: TInventoryManager;
    FEconomy: TEconomyManager;

    FPath: TPathList;
    FPathIndex: Integer;
    FMoveSpeed: Single;

    FPriceTolerance: Single;
    FTargetProduct: String[20];
    FCartTotal: Int64;
    FWaitTimer: Integer;

    FLastQueueIndex: Integer;
    FDrawX, FDrawY: Single;

    function GetQueueTargetPos: TGridPos;
    procedure UpdateQueueLogic;

    procedure SetState(ANewState: TNPCState);
    procedure MoveAlongPath;
    procedure EvaluatePurchase;

    function FindTile(AType: TTileType; out OutPos: TGridPos): Boolean;
    function CheckWalkable(AX, AY: Integer): Boolean;
    function GetAdjacentWalkable(ATilePos: TGridPos): TGridPos;
  public
    IsDead: Boolean;

    constructor Create(AStartX, AStartY: Integer; AGrid: TWorldGrid; AInv: TInventoryManager; AEco: TEconomyManager);
    destructor Destroy; override;

    procedure Update;

    property Pos: TFloatPos read FPos;
    property GridPos: TGridPos read FGridPos;
    property State: TNPCState read FState;
    property DrawX: Single read FDrawX;
    property DrawY: Single read FDrawY;
  end;

  TCustomerList = specialize TFPGObjectList<TCustomerAI>;

implementation

var
  CashierQueue: TList;

constructor TCustomerAI.Create(AStartX, AStartY: Integer; AGrid: TWorldGrid; AInv: TInventoryManager; AEco: TEconomyManager);
begin
  FGrid := AGrid;
  FInventory := AInv;
  FEconomy := AEco;

  FGridPos := uGameTypes.GridPos(AStartX, AStartY);
  FPos := FloatPos(AStartX, AStartY);

  FPath := nil;
  IsDead := False;
  FCartTotal := 0;
  FLastQueueIndex := -1;

  FMoveSpeed := 0.08 + (Random(5) * 0.01);
  FPriceTolerance := 0.8 + (Random(10) * 0.1);

  SetState(nsSpawn);
  FDrawX := FPos.X;
  FDrawY := FPos.Y;
end;

destructor TCustomerAI.Destroy;
begin
  CashierQueue.Remove(Self);
  if Assigned(FPath) then FreeAndNil(FPath);
  inherited Destroy;
end;

function TCustomerAI.CheckWalkable(AX, AY: Integer): Boolean;
begin
  Result := FGrid.IsWalkable(AX, AY);
end;

function TCustomerAI.FindTile(AType: TTileType; out OutPos: TGridPos): Boolean;
var
  x, y: Integer;
  FoundTiles: array of TGridPos;
begin
  SetLength(FoundTiles, 0);

  // 1. Kumpulkan semua koordinat tile yang sesuai
  for x := 0 to GRID_COLS - 1 do
  begin
    for y := 0 to GRID_ROWS - 1 do
    begin
      if FGrid.GetCellPtr(x, y)^.TileType = AType then
      begin
        SetLength(FoundTiles, Length(FoundTiles) + 1);
        FoundTiles[High(FoundTiles)] := uGameTypes.GridPos(x, y);
      end;
    end;
  end;

  // 2. Jika ada yang ditemukan, pilih salah satu secara acak (Random)
  if Length(FoundTiles) > 0 then
  begin
    OutPos := FoundTiles[Random(Length(FoundTiles))];
    Result := True;
  end
  else
    Result := False;
end;

function TCustomerAI.GetAdjacentWalkable(ATilePos: TGridPos): TGridPos;
var
  i, nx, ny: Integer;
begin
  for i := 0 to 3 do
  begin
    case i of
      0: begin nx := ATilePos.X; ny := ATilePos.Y - 1; end;
      1: begin nx := ATilePos.X + 1; ny := ATilePos.Y; end;
      2: begin nx := ATilePos.X; ny := ATilePos.Y + 1; end;
      3: begin nx := ATilePos.X - 1; ny := ATilePos.Y; end;
      else begin nx := ATilePos.X; ny := ATilePos.Y; end;
    end;

    if CheckWalkable(nx, ny) then
    begin
      Result := uGameTypes.GridPos(nx, ny);
      Exit;
    end;
  end;
  Result := uGameTypes.GridPos(-1, -1);
end;

function TCustomerAI.GetQueueTargetPos: TGridPos;
var
  x, y: Integer;
  CashierPos: TGridPos;
  MyIndex: Integer;
  TargetX: Integer;
begin
  CashierPos := uGameTypes.GridPos(-1, -1);

  for x := 0 to GRID_COLS - 1 do
  begin
    for y := 0 to GRID_ROWS - 1 do
    begin
      if FGrid.GetCellPtr(x, y)^.TileType = ttCashier then
      begin
        CashierPos := uGameTypes.GridPos(x, y);
        Break;
      end;
    end;
    if CashierPos.X <> -1 then Break;
  end;

  MyIndex := CashierQueue.IndexOf(Self);
  if MyIndex < 0 then MyIndex := 0;

  // Cegah antrean menabrak batas kiri peta (Out of Bounds)
  TargetX := CashierPos.X - 1 - MyIndex;
  if TargetX < 0 then TargetX := 0;

  Result := uGameTypes.GridPos(TargetX, CashierPos.Y);
end;

procedure TCustomerAI.UpdateQueueLogic;
var
  CurrentIndex: Integer;
  TargetPos: TGridPos;
begin
  CurrentIndex := CashierQueue.IndexOf(Self);
  if CurrentIndex < 0 then Exit;

  if CurrentIndex <> FLastQueueIndex then
  begin
    FLastQueueIndex := CurrentIndex;
    TargetPos := GetQueueTargetPos;

    if Assigned(FPath) then FreeAndNil(FPath);
    FPath := FindPath(FGridPos, TargetPos, @CheckWalkable);
    FPathIndex := 0;

    // SISTEM ANTI-MACET (Failsafe)
    if FPath = nil then
    begin
      FGridPos := TargetPos;
      FPos.X := TargetPos.X;
      FPos.Y := TargetPos.Y;
    end;
  end;

  if (CurrentIndex = 0) and (FPath = nil) then
  begin
    TargetPos := GetQueueTargetPos;
    if (FGridPos.X = TargetPos.X) and (FGridPos.Y = TargetPos.Y) then
    begin
      SetState(nsPaying);
    end;
  end;
end;

procedure TCustomerAI.SetState(ANewState: TNPCState);
var
  TargetPos: TGridPos;
  RollChanceItem: Integer;
begin
  FState := ANewState;

  case FState of
    nsSpawn:
      begin
        RollChanceItem := Random(100);

        case FEconomy.Weather of
          wtClear:
            begin
              if RollChanceItem < 34 then FTargetProduct := 'BRS-01'
              else if RollChanceItem < 67 then FTargetProduct := 'MIE-01'
              else FTargetProduct := 'MIN-01';
            end;
          wtRain:
            begin
              if RollChanceItem < 15 then FTargetProduct := 'BRS-01'
              else if RollChanceItem < 85 then FTargetProduct := 'MIE-01'
              else FTargetProduct := 'MIN-01';
            end;
          wtHot:
            begin
              if RollChanceItem < 15 then FTargetProduct := 'BRS-01'
              else if RollChanceItem < 30 then FTargetProduct := 'MIE-01'
              else FTargetProduct := 'MIN-01';
            end;
        end;

        SetState(nsPathfinding);
      end;

    nsPathfinding:
      begin
        if FindTile(ttRack, TargetPos) then
        begin
          TargetPos := GetAdjacentWalkable(TargetPos);

          if TargetPos.X <> -1 then
          begin
            if Assigned(FPath) then FreeAndNil(FPath);
            FPath := FindPath(FGridPos, TargetPos, @CheckWalkable);
            FPathIndex := 0;

            if FPath = nil then SetState(nsLeaving);
          end
          else SetState(nsLeaving);
        end
        else SetState(nsLeaving);
      end;

    nsBrowsing:
      begin
        FWaitTimer := 30;
      end;

    nsQueueing:
      begin
        if CashierQueue.IndexOf(Self) < 0 then
          CashierQueue.Add(Self);

        FLastQueueIndex := -1;
      end;

    nsPaying:
      begin
        FWaitTimer := 45;
      end;

    nsLeaving:
      begin
        CashierQueue.Remove(Self);

        if FindTile(ttDoor, TargetPos) then
        begin
          if Assigned(FPath) then FreeAndNil(FPath);
          FPath := FindPath(FGridPos, TargetPos, @CheckWalkable);
          FPathIndex := 0;
        end
        else IsDead := True;
      end;
  end;
end;

procedure TCustomerAI.EvaluatePurchase;
var
  Def: TProductDef;
  DemandMod, Prob: Single;
  AltItem: TStockItem;
  FoundAlt: Boolean;
  RandIdx, i: Integer;
  ActualPrice: Integer; // --> PENAMBAHAN VARIABEL BARU UNTUK DYNAMIC PRICING
begin
  // 1. Cek apakah barang target benar-benar ada di database
  if not FInventory.GetProductDef(FTargetProduct, Def) then
  begin
    SetState(nsLeaving);
    Exit;
  end;

  // =========================================================
  // 2. BACA HARGA FISIK DI RAK SEKARANG (Dynamic Pricing)
  // =========================================================
  ActualPrice := Def.BaseCost + 5000; // Harga default (Failsafe) jika tidak ketemu

  for i := 0 to FInventory.Stocks.Count - 1 do
  begin
    if FInventory.Stocks[i].ProductID = FTargetProduct then
    begin
      ActualPrice := FInventory.Stocks[i].SellPrice; // Ambil harga riil dari kardus barang!
      Break;
    end;
  end;

  DemandMod := FEconomy.GetDemandModifier(Def.Category);

  // 3. Evaluasi Harga Baru dengan Toleransi Pasar
  Prob := CalcPurchaseProbability(ActualPrice, Def.BaseCost, FPriceTolerance, DemandMod);

  if RollChance(Prob) then
  begin
    // =========================================================
    // SKENARIO A: Sukses Mengambil Barang Incaran Utama
    // =========================================================
    if FInventory.TakeItem(FTargetProduct) then
    begin
      // POTONG UANG BERDASARKAN HARGA YANG DITETAPKAN PEMAIN!
      FCartTotal := FCartTotal + ActualPrice;
    end
    else
    begin
      // =========================================================
      // SKENARIO B: Barang Utama Kosong -> Impulse Buying
      // =========================================================
      FoundAlt := False;

      if FInventory.Stocks.Count > 0 then
      begin
        RandIdx := Random(FInventory.Stocks.Count);
        AltItem := FInventory.Stocks[RandIdx];

        if (AltItem.Qty > 0) and (Random(100) < 50) then
        begin
          if FInventory.TakeItem(String(AltItem.ProductID)) then
          begin
            FCartTotal := FCartTotal + AltItem.SellPrice; // Barang alternatif juga potong harga jualnya
            FoundAlt := True;

            FXManager.SpawnText('Beli ini aja deh!', FPos.X, FPos.Y, clYellow);
          end;
        end;
      end;

      // =========================================================
      // SKENARIO C: Gagal Total (Rak Kosong)
      // =========================================================
      if not FoundAlt then
      begin
        FXManager.SpawnText('Yah, Kosong!', FPos.X, FPos.Y, clWhite);
        SoundFX.PlaySFX('error.wav');
      end;
    end;
  end
  else
  begin
    // =========================================================
    // SKENARIO D: Barang Tersedia, Tapi AI Merasa Terlalu MAHAL!
    // =========================================================
    FXManager.SpawnText('Kemahalan!', FPos.X, FPos.Y, clWhite);
  end;

  // 4. Keputusan Akhir AI
  if FCartTotal > 0 then
    SetState(nsQueueing)
  else
    SetState(nsLeaving);
end;

procedure TCustomerAI.MoveAlongPath;
var
  TargetGrid: TGridPos;
begin
  if (FPath = nil) or (FPathIndex >= FPath.Count) then
  begin
    FreeAndNil(FPath);

    case FState of
      nsPathfinding: SetState(nsBrowsing);
      nsLeaving:     IsDead := True;
    end;
    Exit;
  end;

  TargetGrid := FPath[FPathIndex];

  FPos.X := MoveTowards(FPos.X, TargetGrid.X, FMoveSpeed);
  FPos.Y := MoveTowards(FPos.Y, TargetGrid.Y, FMoveSpeed);

  if (Abs(FPos.X - TargetGrid.X) < 0.05) and (Abs(FPos.Y - TargetGrid.Y) < 0.05) then
  begin
    FPos.X := TargetGrid.X;
    FPos.Y := TargetGrid.Y;
    FGridPos := TargetGrid;
    Inc(FPathIndex);
  end;
end;

procedure TCustomerAI.Update;
begin
  case FState of
    nsPathfinding, nsLeaving:
      MoveAlongPath;

    nsQueueing:
      begin
        UpdateQueueLogic;
        MoveAlongPath;
      end;

    nsBrowsing:
      begin
        Dec(FWaitTimer);
        if FWaitTimer <= 0 then EvaluatePurchase;
      end;

    nsPaying:
      begin
        Dec(FWaitTimer);
        if FWaitTimer <= 0 then
        begin
          FEconomy.AddCash(FCartTotal);

          if FCartTotal > 0 then
             begin
             FXManager.SpawnText('+Rp ' + IntToStr(FCartTotal), FPos.X, FPos.Y, clLime);
             SoundFX.PlaySFX('cash.wav');
             end;

          FCartTotal := 0;
          SetState(nsLeaving);
        end;
      end;
  end;

  FDrawX := FDrawX + (FPos.X - FDrawX) * 0.15;
  FDrawY := FDrawY + (FPos.Y - FDrawY) * 0.15;
end;

initialization
  CashierQueue := TList.Create;
finalization
  CashierQueue.Free;
end.
