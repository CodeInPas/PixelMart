unit uRenderer;

{$mode objfpc}{$H+}
{$INLINE ON}
{$OPTIMIZATION LEVEL3}


interface

uses
  Classes, Graphics, Types, SysUtils, math,
  uConstants, uGameTypes, uDoubleBuffer, uWorldGrid, uCustomerAI, uEconomyLogic,
  uInventorySys, uSpriteManager, uStaffAI; // -> PERBAIKAN: Menambahkan uStaffAI untuk menggambar Kasir

type
  { TGameRenderer
    Mesin utama untuk menggambar seluruh grafis game ke memory buffer. }
  TGameRenderer = class
  private
    FBuffer: TDoubleBuffer;
    FGrid: TWorldGrid;
    FCustomers: TCustomerList;
    FEconomy: TEconomyManager;
    FInventory: TInventoryManager;

    procedure DrawWorld; inline;
    procedure DrawEntities; inline;
    procedure DrawHUD; inline;
  public
    constructor Create(ABuffer: TDoubleBuffer; AGrid: TWorldGrid; ACustomers: TCustomerList; AEco: TEconomyManager; AInv: TInventoryManager);
    destructor Destroy; override;

    procedure RenderFrame;
  end;

implementation

constructor TGameRenderer.Create(ABuffer: TDoubleBuffer; AGrid: TWorldGrid; ACustomers: TCustomerList; AEco: TEconomyManager; AInv: TInventoryManager);
begin
  FBuffer := ABuffer;
  FGrid := AGrid;
  FCustomers := ACustomers;
  FEconomy := AEco;
  FInventory := AInv;
end;

destructor TGameRenderer.Destroy;
begin
  inherited Destroy;
end;

procedure TGameRenderer.DrawWorld; inline;
var
  x, y: Integer;
  Cell: PGridCell;
  RectPos, ItemRect: TRect;
  Canvas: TCanvas;
  StockIdx: Integer;
  StockItem: TStockItem;
  Def: TProductDef;
begin
  Canvas := FBuffer.Canvas;
  StockIdx := 0;

  for x := 0 to GRID_COLS - 1 do
  begin
    for y := 0 to GRID_ROWS - 1 do
    begin
      Cell := FGrid.GetCellPtr(x, y);
      RectPos := Rect(x * TILE_SIZE, y * TILE_SIZE, (x + 1) * TILE_SIZE, (y + 1) * TILE_SIZE);

      // MENGGUNAKAN SPRITE DARI uSpriteManager (Lebih aman dan rapi)
      case Cell^.TileType of
        ttFloor:   Canvas.Draw(RectPos.Left, RectPos.Top, Sprites.BmpFloor);
        ttRack:    Canvas.Draw(RectPos.Left, RectPos.Top, Sprites.BmpRack);
        ttCashier: Canvas.Draw(RectPos.Left, RectPos.Top, Sprites.BmpCashier);
        ttDoor:    Canvas.Draw(RectPos.Left, RectPos.Top, Sprites.BmpDoor);
      end;

      // RENDER OVERLAY BARANG DI ATAS RAK
      if (Cell^.TileType = ttRack) and (StockIdx < FInventory.Stocks.Count) then
      begin
        StockItem := FInventory.Stocks[StockIdx];
        if FInventory.GetProductDef(StockItem.ProductID, Def) then
        begin
          case Def.Category of
            pcStaple:   Canvas.Brush.Color := clWhite;
            pcSnack:    Canvas.Brush.Color := $006666FF;
            pcTertiary: Canvas.Brush.Color := $00FF6666;
          end;

          ItemRect := Rect(RectPos.Left + 6, RectPos.Top + 6, RectPos.Right - 6, RectPos.Bottom - 6);
          Canvas.FillRect(ItemRect);

          Canvas.Font.Name := 'Arial';
          Canvas.Font.Size := 8;
          Canvas.Font.Style := [fsBold];
          Canvas.Font.Color := clBlack;
          Canvas.Brush.Style := bsClear;

          Canvas.TextOut(RectPos.Left + 8, RectPos.Top + 8, IntToStr(StockItem.Qty));
          Canvas.Brush.Style := bsSolid;
        end;
        Inc(StockIdx);
      end;
    end;
  end;
end;

procedure TGameRenderer.DrawEntities; inline;
var
  i: Integer;
  NPC: TCustomerAI;
  cx, cy, BobbingOffset: Integer;
  Canvas: TCanvas;
begin
  Canvas := FBuffer.Canvas;

  for i := 0 to FCustomers.Count - 1 do
  begin
    NPC := FCustomers[i];

    // 1. Konversi posisi Visual LERP ke Layar (Sudut Kiri Atas Sprite)
    cx := Trunc(NPC.DrawX * TILE_SIZE);
    cy := Trunc(NPC.DrawY * TILE_SIZE);

    // 2. EFEK MEMANTUL (WALKING BOBBING EFFECT)
    BobbingOffset := 0;
    if (Abs(NPC.Pos.X - NPC.DrawX) > 0.05) or (Abs(NPC.Pos.Y - NPC.DrawY) > 0.05) then
    begin
      BobbingOffset := Trunc(Abs(Sin(NPC.DrawX * 15 + NPC.DrawY * 15)) * 4);
    end;

    // Kurangi Y agar sprite melompat ke atas
    cy := cy - BobbingOffset;

    // 3. GAMBAR SPRITE PELANGGAN (Dari uSpriteManager)
    Canvas.Draw(cx, cy, Sprites.BmpCustomer);

    // 4. GAMBAR INDIKATOR STATUS
    // Menggunakan Brush.Style Solid agar warna tidak tembus pandang
    Canvas.Brush.Style := bsSolid;

    case NPC.State of
      nsBrowsing:
        begin
          Canvas.Brush.Color := clYellow;
          Canvas.Pen.Color := clBlack;
          // Kotak indikator (Lebar 8px, Tinggi 8px) di pojok atas sprite pelanggan
          Canvas.Rectangle(cx + 24, cy, cx + 32, cy + 8);
        end;
      nsPaying:
        begin
          Canvas.Brush.Color := clLime;
          Canvas.Pen.Color := clBlack;
          Canvas.Rectangle(cx + 24, cy, cx + 32, cy + 8);
        end;
    end;
  end;

  // --> INJEKSI: Memastikan Staff (Kasir AI) digambar di atas dunia
  KasirAI.Draw(Canvas);
end;

procedure TGameRenderer.DrawHUD; inline;
var
  Canvas: TCanvas;
  InfoStr, WeatherStr: String;
begin
  Canvas := FBuffer.Canvas;

  // 1. GAMBAR KOTAK PANEL BACKGROUND HUD (Solusi Anti-Ghosting)
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := $00222222; // Warna abu-abu sangat gelap
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Color := clWhite;     // Garis tepi (border) warna putih
  // Gambar kotak dari pojok kiri atas menutupi area teks
  Canvas.Rectangle(5, 5, 230, 55);

  // 2. SETUP FONT DASAR
  Canvas.Font.Name := 'Arial';
  Canvas.Font.Size := 10;
  Canvas.Font.Style := [fsBold];
  Canvas.Brush.Style := bsClear; // Transparan agar teks menyatu dengan kotak panel

  // 3. TEKS INFO HARI & UANG
  InfoStr := Format('Day: %d | Cash: Rp %g', [FEconomy.DayCount, FEconomy.Cash * 1.0]);

  Canvas.Font.Color := clBlack; // Efek Bayangan (Shadow)
  Canvas.TextOut(11, 11, InfoStr);

  Canvas.Font.Color := clWhite; // Teks Utama
  Canvas.TextOut(10, 10, InfoStr);

  // 4. TEKS INFO CUACA
  case FEconomy.Weather of
    wtClear: WeatherStr := 'Weather: Sunny';
    wtRain:  WeatherStr := 'Weather: Rain';
    wtHot:   WeatherStr := 'Weather: Heatwave';
  end;

  Canvas.Font.Color := clBlack; // Efek Bayangan (Shadow)
  Canvas.TextOut(11, 31, WeatherStr);

  Canvas.Font.Color := clYellow; // Teks Utama
  Canvas.TextOut(10, 30, WeatherStr);
end;

procedure TGameRenderer.RenderFrame;
begin
  DrawWorld;
  DrawEntities;
  DrawHUD;
end;

end.
