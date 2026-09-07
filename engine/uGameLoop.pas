unit uGameLoop;

{$mode objfpc}{$H+}
{$OPTIMIZATION LEVEL3}

interface

uses
  Classes, SysUtils, ExtCtrls, Graphics, Controls, Math,
  uConstants, uGameTypes, uWorldGrid, uInventorySys, uEconomyLogic,
  uCustomerAI, uDoubleBuffer, uRenderer, uSaveLoad, uVisuals, uStaffAI;

type
  // --> DELEGATE BARU: Definisi Sinyal Perubahan State
  TStateChangeEvent = procedure(NewState: Integer) of object;

  { TGameLoop
    Mesin utama yang mengorkestrasi sistem, state, input, dan rendering LCL. }
  TGameLoop = class
  private
    // Komponen Timer LCL untuk memutar siklus frame (Game Tick)
    FTimer: TTimer;
    FTargetCanvas: TCanvas; // Kanvas TPaintBox milik Form utama

    // Core Systems
    FGrid: TWorldGrid;
    FInventory: TInventoryManager;
    FEconomy: TEconomyManager;
    FCustomers: TCustomerList;

    // Rendering Systems
    FBuffer: TDoubleBuffer;
    FRenderer: TGameRenderer;

    // State & Clock
    FGameState: Integer;
    FDayTickCounter: Integer;
    FMaxDayTicks: Integer;

    FOnStateChanged: TStateChangeEvent; // --> Event Pointer

    procedure OnTimerTick(Sender: TObject);

    procedure UpdateLogic;
    procedure SpawnCustomerRoutine;
    procedure CleanupDeadEntities;
  public
    constructor Create(APaintBox: TGraphicControl);
    destructor Destroy; override;

    procedure ChangeState(ANewState: Integer);

    // Akses properti untuk UI (fMain)
    property GameState: Integer read FGameState;
    property Inventory: TInventoryManager read FInventory;
    property Economy: TEconomyManager read FEconomy;
    property Grid: TWorldGrid read FGrid;

    procedure SaveGame(const AFileName: String);
    function LoadGame(const AFileName: String): Boolean;

    // --> EXPOSE EVENT KE LUAR
    property OnStateChanged: TStateChangeEvent read FOnStateChanged write FOnStateChanged;
  end;

implementation

constructor TGameLoop.Create(APaintBox: TGraphicControl);
begin
  // Inisialisasi Kanvas Target (Blit Destination)
  FTargetCanvas := APaintBox.Canvas;

  // 1. Inisialisasi Sistem Data & Logika
  FGrid := TWorldGrid.Create;
  FInventory := TInventoryManager.Create;
  FInventory.LoadProductsFromCSV; // Load master data

  FEconomy := TEconomyManager.Create(FInventory);
  FCustomers := TCustomerList.Create;

  // 2. Inisialisasi Sistem Visual
  FBuffer := TDoubleBuffer.Create(VIEWPORT_WIDTH, VIEWPORT_HEIGHT, COLOR_BG_FLOOR);

  // PERBAIKAN: Menambahkan FInventory sebagai parameter ke-5
  FRenderer := TGameRenderer.Create(FBuffer, FGrid, FCustomers, FEconomy, FInventory);

  // 3. Kalkulasi Batas Tick per Hari
  // Jika 1 detik = (1000 / 33) = ~30 Ticks
  FMaxDayTicks := DAY_DURATION_SEC * (1000 div MS_PER_UPDATE);

  // 4. Inisialisasi Game Clock (Timer)
  FTimer := TTimer.Create(nil);
  FTimer.Interval := MS_PER_UPDATE;
  FTimer.OnTimer := @OnTimerTick;
  FTimer.Enabled := False;

  // Start Phase
  ChangeState(STATE_PREP);
end;

destructor TGameLoop.Destroy;
begin
  FTimer.Enabled := False;
  FTimer.Free;

  FRenderer.Free;
  FBuffer.Free;

  FCustomers.Free;
  FEconomy.Free;
  FInventory.Free;
  FGrid.Free;

  inherited Destroy;
end;

procedure TGameLoop.ChangeState(ANewState: Integer);
var
  SpoilageCost: Integer;
  StaffSalary: Int64; // --> Tambahkan variabel ini
begin
  FGameState := ANewState;

  case FGameState of
    STATE_PREP:
      begin
        FCustomers.Clear;
        FTimer.Enabled := True;
      end;

    STATE_OPEN:
      begin
        FEconomy.StartNewDay;
        FDayTickCounter := 0;
        FTimer.Enabled := True;
      end;

    STATE_SUMMARY:
      begin
        // 1. Potong umur barang & hitung rugi kedaluwarsa
        FInventory.ProcessEndOfDay(SpoilageCost);

        // 2. HITUNG GAJI KARYAWAN
        StaffSalary := 0;
        if KasirAI.IsHired then
          StaffSalary := 75000; // --> Gaji Harian Kasir: Rp 75.000

        // 3. Tutup buku dan masukkan semua beban
        FEconomy.EndOfDay(SpoilageCost, StaffSalary);

        // 4. Bersihkan pelanggan yang tersisa
        FCustomers.Clear;
      end;

    STATE_GAMEOVER:
      begin
        FTimer.Enabled := False;
      end;
  end;

  if Assigned(FOnStateChanged) then
    FOnStateChanged(FGameState);
end;

procedure TGameLoop.SpawnCustomerRoutine;
var
  SpawnProb: Single;
  NewNPC: TCustomerAI;
  SpawnX, SpawnY: Integer;
begin
  // Batasi jumlah maksimal orang di dalam toko (Optimization Limit)
  if FCustomers.Count >= MAX_NPC_ACTIVE then Exit;

  // Probabilitas spawn (misal: ~2% per frame, disesuaikan cuaca/modifier)
  SpawnProb := 0.02 * FEconomy.GetDemandModifier(pcStaple);

  if Random < SpawnProb then
  begin
    // Asumsi Pintu Utama ada di tengah bawah grid (sesuai uWorldGrid)
    SpawnX := GRID_COLS div 2;
    SpawnY := GRID_ROWS - 1;

    NewNPC := TCustomerAI.Create(SpawnX, SpawnY, FGrid, FInventory, FEconomy);
    FCustomers.Add(NewNPC);
  end;
end;

procedure TGameLoop.CleanupDeadEntities;
var
  i: Integer;
begin
  // REVERSE LOOP: Eksekusi penghapusan dari indeks paling belakang ke depan
  for i := FCustomers.Count - 1 downto 0 do
  begin
    if FCustomers[i].IsDead then
    begin
      FCustomers.Delete(i);
    end;
  end;
end;

procedure TGameLoop.UpdateLogic;
var
  i, x, y, DeskX, DeskY: Integer;
begin
  // =========================================================================
  // LOGIKA GLOBAL (Berjalan di Pagi & Siang Hari)
  // =========================================================================

  // --> 1. SCAN KASIR AI: Cari Meja Kasir setiap frame (Agar responsif di Build Mode)
  DeskX := -1; DeskY := -1;
  for x := 0 to GRID_COLS - 1 do
  begin
    for y := 0 to GRID_ROWS - 1 do
    begin
      if FGrid.GetCellPtr(x, y)^.TileType = ttCashier then
      begin
        DeskX := x;
        DeskY := y;
        Break;
      end;
    end;
    if DeskX <> -1 then Break; // Optimasi: Langsung hentikan pencarian jika sudah ketemu
  end;

  // Beri tahu Kasir posisi meja kerjanya
  KasirAI.Update(DeskX, DeskY);

  // --> 2. EFEK VISUAL: Animasi teks melayang tetap di-update agar tidak beku
  FXManager.Update;


  // =========================================================================
  // LOGIKA KHUSUS GAMEPLAY (Hanya berjalan saat Siang/Warung Buka)
  // =========================================================================
  if FGameState = STATE_OPEN then
  begin
    // 1. Tick Clock Hari
    Inc(FDayTickCounter);
    if FDayTickCounter >= FMaxDayTicks then
    begin
      ChangeState(STATE_SUMMARY);
      Exit;
    end;

    // 2. Spawn NPC baru
    SpawnCustomerRoutine;

    // 3. Update Logika Semua AI secara Sinkron (Tidak pakai Thread!)
    for i := 0 to FCustomers.Count - 1 do
    begin
      FCustomers[i].Update;
    end;

    // 4. Buang NPC yang sudah selesai bayar atau pergi
    CleanupDeadEntities;
  end;
end;

procedure TGameLoop.OnTimerTick(Sender: TObject);
begin
  // Pipa Utama Eksekusi Game (Main Pipeline)
  UpdateLogic;
  FRenderer.RenderFrame;
  FXManager.Draw(FBuffer.Canvas);
  FBuffer.Flip(FTargetCanvas);
end;

procedure TGameLoop.SaveGame(const AFileName: String);
begin
  uSaveLoad.SaveGameData(AFileName, FGrid, FInventory, FEconomy);
end;

function TGameLoop.LoadGame(const AFileName: String): Boolean;
begin
  Result := uSaveLoad.LoadGameData(AFileName, FGrid, FInventory, FEconomy);
end;

end.
