unit uWorldGrid;

{$mode objfpc}{$H+}
{$INLINE ON}
{$OPTIMIZATION LEVEL3}

interface

uses
  SysUtils, uConstants, uGameTypes;

type
  { TWorldGrid
    Mengelola tata ruang warung, posisi rintangan, lantai, pintu, dan id rak. }
  TWorldGrid = class
  private
    // Array statis 2D yang sangat cepat. Alokasi memori berdekatan (Contiguous memory).
    FCells: array[0..GRID_COLS-1, 0..GRID_ROWS-1] of TGridCell;

    function InBounds(AX, AY: Integer): Boolean; inline;
  public
    constructor Create;

    { Membangun tembok keliling, lantai dasar, kasir, dan pintu secara default }
    procedure InitDefaultMap;

    { Mengambil pointer referensi langsung ke memori sel untuk dimodifikasi }
    function GetCellPtr(AX, AY: Integer): PGridCell; inline;

    { Setter cepat untuk memanipulasi sel secara aman }
    procedure SetTile(AX, AY: Integer; ATileType: TTileType; ARackID: Integer = -1); inline;

    { Fungsi Validasi khusus yang di-passing ke algoritma A-Star Pathfinding }
    function IsWalkable(AX, AY: Integer): Boolean;
  end;

implementation

constructor TWorldGrid.Create;
begin
  // Pastikan blok memori bersih dari data sampah sebelum digunakan
  FillChar(FCells, SizeOf(FCells), 0);
  InitDefaultMap;
end;

function TWorldGrid.InBounds(AX, AY: Integer): Boolean; inline;
begin
  Result := (AX >= 0) and (AX < GRID_COLS) and (AY >= 0) and (AY < GRID_ROWS);
end;

function TWorldGrid.GetCellPtr(AX, AY: Integer): PGridCell; inline;
begin
  if InBounds(AX, AY) then
    Result := @FCells[AX, AY] // Return memory address
  else
    Result := nil;
end;

procedure TWorldGrid.SetTile(AX, AY: Integer; ATileType: TTileType; ARackID: Integer = -1); inline;
var
  CellPtr: PGridCell;
begin
  CellPtr := GetCellPtr(AX, AY);
  if CellPtr <> nil then
  begin
    CellPtr^.TileType := ATileType;
    CellPtr^.RackID := ARackID;

    // Tentukan apakah NPC bisa lewat. Pintu, Lantai, dan Kasir (area belakang) bisa dilewati.
    CellPtr^.IsWalkable := (ATileType = ttFloor) or (ATileType = ttDoor);
  end;
end;

function TWorldGrid.IsWalkable(AX, AY: Integer): Boolean;
begin
  if not InBounds(AX, AY) then
    Exit(False);

  Result := FCells[AX, AY].IsWalkable;
end;

procedure TWorldGrid.InitDefaultMap;
var
  x, y: Integer;
begin
  // 1. Loop O(N^2) untuk mereset seluruh grid ke Lantai (Floor)
  for x := 0 to GRID_COLS - 1 do
  begin
    for y := 0 to GRID_ROWS - 1 do
    begin
      SetTile(x, y, ttFloor);
    end;
  end;

  // 2. Bangun Tembok (Borders)
  // Tembok Atas dan Bawah
  for x := 0 to GRID_COLS - 1 do
  begin
    SetTile(x, 0, ttWall);
    SetTile(x, GRID_ROWS - 1, ttWall);
  end;

  // Tembok Kiri dan Kanan
  for y := 0 to GRID_ROWS - 1 do
  begin
    SetTile(0, y, ttWall);
    SetTile(GRID_COLS - 1, y, ttWall);
  end;

  // 3. Pasang Pintu Utama (Tengah bawah tembok)
  // NPC akan spawn dari titik ini
  SetTile(GRID_COLS div 2, GRID_ROWS - 1, ttDoor);

  // 4. Area Kasir Default (Kanan bawah, dekat pintu)
  // (Contoh koordinat statis: X=20, Y=15)
  SetTile(GRID_COLS - 4, GRID_ROWS - 3, ttCashier);
  SetTile(GRID_COLS - 3, GRID_ROWS - 3, ttCashier);

  // Catatan: Rak (ttRack) tidak diinisialisasi di sini karena pemain
  // yang akan meletakkannya secara dinamis saat Fase Pagi (Prep Phase).
end;

end.

