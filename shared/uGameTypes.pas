unit uGameTypes;

{$mode objfpc}{$H+}
// Wajib ditambahkan agar Record bisa memiliki fungsi (metode) layaknya Class
{$modeswitch advancedrecords}

interface

uses
  Classes, fgl, uConstants;

type
  // =========================================================================
  // 1. FUNDAMENTAL DATA TYPES (Koordinat)
  // =========================================================================

  { Posisi presisi absolut di memori grid (Kolom, Baris) }
  TGridPos = record
    X, Y: Integer;
    // Overload di dalam Record
    class operator = (const A, B: TGridPos): Boolean; inline;
  end;

  { Posisi floating point untuk rendering pergerakan Sprite (Interpolasi Pixel) }
  TFloatPos = record
    X, Y: Single;
  end;

  // =========================================================================
  // 2. ENUMERATIONS (State Machine & Kategori)
  // =========================================================================

  { Tipe lantai/rintangan di dalam Grid }
  TTileType = (ttFloor, ttWall, ttDoor, ttRack, ttCashier);

  { State-Machine untuk AI Pelanggan }
  TNPCState = (
    nsSpawn,           // Muncul di pintu
    nsPathfinding,     // Mencari rute ke rak
    nsBrowsing,        // Memilih barang di depan rak (idle sementara)
    nsQueueing,        // Antre di kasir
    nsPaying,          // Proses transaksi
    nsLeaving          // Berjalan keluar
  );

  { Kategori produk untuk logika ekonomi & preferensi NPC }
  TProductCategory = (pcStaple, pcSnack, pcTertiary);

  // =========================================================================
  // 3. RECORDS (Struktur Data Ringan & Cepat)
  // =========================================================================

  { Definisi master dari sebuah produk }
  TProductDef = record
    ID: String[20];
    Name: String[50];
    Category: TProductCategory;
    BaseCost: Integer;
    MaxExpiry: Integer;
    // Overload di dalam Record
    class operator = (const A, B: TProductDef): Boolean; inline;
  end;

  { Data spesifik stok barang yang saat ini dimiliki/dijual }
  TStockItem = record
    ProductID: String[20];
    Qty: Integer;
    SellPrice: Integer;
    DaysToExpiry: Integer;
    // Overload di dalam Record
    class operator = (const A, B: TStockItem): Boolean; inline;
  end;

  { Struktur tunggal untuk 1 sel di dalam peta (Grid) }
  PGridCell = ^TGridCell;
  TGridCell = record
    TileType: TTileType;
    IsWalkable: Boolean;
    RackID: Integer;
  end;

  // =========================================================================
  // 4. GENERICS COLLECTIONS (fgl)
  // =========================================================================

  { Map/Dictionary berkecepatan tinggi (Key: String ID, Value: TProductDef) }
  TProductDefMap = specialize TFPGMap<String, TProductDef>;

  { List dinamis untuk tumpukan stok di inventori }
  TStockList = specialize TFPGList<TStockItem>;

  { List titik koordinat untuk hasil rute algoritma Pathfinding }
  TPathList = specialize TFPGList<TGridPos>;

// =========================================================================
// 5. INLINE HELPERS
// =========================================================================
function GridPos(AX, AY: Integer): TGridPos; inline;
function FloatPos(AX, AY: Single): TFloatPos; inline;
function PosIsEqual(const P1, P2: TGridPos): Boolean; inline;

implementation

// =========================================================================
// IMPLEMENTASI CLASS OPERATOR OVERLOADING (Advanced Records)
// =========================================================================

class operator TGridPos.= (const A, B: TGridPos): Boolean; inline;
begin
  Result := (A.X = B.X) and (A.Y = B.Y);
end;

class operator TProductDef.= (const A, B: TProductDef): Boolean; inline;
begin
  Result := (A.ID = B.ID) and
            (A.Name = B.Name) and
            (A.Category = B.Category) and
            (A.BaseCost = B.BaseCost) and
            (A.MaxExpiry = B.MaxExpiry);
end;

class operator TStockItem.= (const A, B: TStockItem): Boolean; inline;
begin
  Result := (A.ProductID = B.ProductID) and
            (A.Qty = B.Qty) and
            (A.SellPrice = B.SellPrice) and
            (A.DaysToExpiry = B.DaysToExpiry);
end;

// =========================================================================
// IMPLEMENTASI INLINE HELPERS
// =========================================================================

function GridPos(AX, AY: Integer): TGridPos; inline;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function FloatPos(AX, AY: Single): TFloatPos; inline;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function PosIsEqual(const P1, P2: TGridPos): Boolean; inline;
begin
  Result := (P1.X = P2.X) and (P1.Y = P2.Y);
end;

end.
