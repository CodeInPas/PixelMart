unit uPathfinding;

{$mode objfpc}{$H+}
{$INLINE ON}
{$OPTIMIZATION LEVEL3}

interface

uses
  SysUtils, Classes, uConstants, uGameTypes, uMathHelper;

type
  { Delegate callback untuk mengecek apakah grid bisa dilewati.
    Dipisahkan dari class Grid agar unit ini tetap independen. }
  TGridWalkableFunc = function(AX, AY: Integer): Boolean of object;

{ Fungsi utama Pathfinding A*.
  PENTING: Caller bertanggung jawab untuk memanggil .Free pada TPathList yang direturn! }
function FindPath(const StartPos, TargetPos: TGridPos; WalkableCheck: TGridWalkableFunc): TPathList;

implementation

const
  STATE_UNVISITED = 0;
  STATE_OPEN      = 1;
  STATE_CLOSED    = 2;

  // Arah pergerakan (Atas, Kanan, Bawah, Kiri) - Tidak ada diagonal untuk warung
  DIR_X: array[0..3] of Integer = (0, 1, 0, -1);
  DIR_Y: array[0..3] of Integer = (-1, 0, 1, 0);

type
  TPathNode = record
    ParentX, ParentY: Integer;
    G, F: Integer;
    State: Byte;
  end;

function FindPath(const StartPos, TargetPos: TGridPos; WalkableCheck: TGridWalkableFunc): TPathList;
var
  Nodes: array[0..GRID_COLS-1, 0..GRID_ROWS-1] of TPathNode; // Alokasi Stack (Sangat Cepat)
  OpenList: array[0..(GRID_COLS * GRID_ROWS) - 1] of TGridPos;
  OpenCount: Integer;

  CurrPos, NextPos: TGridPos;
  CurrIdx, BestIdx, i, nx, ny: Integer;
  CostG, CostF: Integer;
  PathFound: Boolean;
begin
  Result := nil;

  // Validasi awal batas koordinat dan target
  if (StartPos.X < 0) or (StartPos.X >= GRID_COLS) or (StartPos.Y < 0) or (StartPos.Y >= GRID_ROWS) or
     (TargetPos.X < 0) or (TargetPos.X >= GRID_COLS) or (TargetPos.Y < 0) or (TargetPos.Y >= GRID_ROWS) then
    Exit;

  if not WalkableCheck(TargetPos.X, TargetPos.Y) then
    Exit; // Target adalah tembok/rak

  if PosIsEqual(StartPos, TargetPos) then
    Exit;

  // Reset grid nodes (Menggunakan FillChar untuk O(1) memory zeroing)
  FillChar(Nodes, SizeOf(Nodes), 0);
  OpenCount := 0;

  // Inisialisasi Start Node
  Nodes[StartPos.X, StartPos.Y].State := STATE_OPEN;
  Nodes[StartPos.X, StartPos.Y].G := 0;
  Nodes[StartPos.X, StartPos.Y].F := ManhattanDistance(StartPos, TargetPos);

  OpenList[0] := StartPos;
  OpenCount := 1;
  PathFound := False;

  // A* Main Loop
  while OpenCount > 0 do
  begin
    // 1. Cari node dengan nilai F terkecil di OpenList
    BestIdx := 0;
    for i := 1 to OpenCount - 1 do
    begin
      if Nodes[OpenList[i].X, OpenList[i].Y].F < Nodes[OpenList[BestIdx].X, OpenList[BestIdx].Y].F then
        BestIdx := i;
    end;

    CurrPos := OpenList[BestIdx];

    // Pop node dari antrean (replace element dengan element terakhir)
    Dec(OpenCount);
    if BestIdx < OpenCount then
      OpenList[BestIdx] := OpenList[OpenCount];

    Nodes[CurrPos.X, CurrPos.Y].State := STATE_CLOSED;

    // 2. Jika target tercapai
    if PosIsEqual(CurrPos, TargetPos) then
    begin
      PathFound := True;
      Break;
    end;

    // 3. Cek tetangga (4 Arah)
    for i := 0 to 3 do
    begin
      nx := CurrPos.X + DIR_X[i];
      ny := CurrPos.Y + DIR_Y[i];

      // Cek batas array & tabrakan objek
      if (nx >= 0) and (nx < GRID_COLS) and (ny >= 0) and (ny < GRID_ROWS) then
      begin
        if (Nodes[nx, ny].State = STATE_CLOSED) or not WalkableCheck(nx, ny) then
          Continue;

        CostG := Nodes[CurrPos.X, CurrPos.Y].G + 10; // 10 = flat cost untuk movement
        CostF := CostG + (ManhattanDistance(GridPos(nx, ny), TargetPos) * 10);

        if Nodes[nx, ny].State = STATE_UNVISITED then
        begin
          // Node baru ditemukan
          Nodes[nx, ny].State := STATE_OPEN;
          Nodes[nx, ny].ParentX := CurrPos.X;
          Nodes[nx, ny].ParentY := CurrPos.Y;
          Nodes[nx, ny].G := CostG;
          Nodes[nx, ny].F := CostF;

          OpenList[OpenCount] := GridPos(nx, ny);
          Inc(OpenCount);
        end
        else if CostG < Nodes[nx, ny].G then
        begin
          // Rute yang lebih baik ditemukan ke node lama
          Nodes[nx, ny].ParentX := CurrPos.X;
          Nodes[nx, ny].ParentY := CurrPos.Y;
          Nodes[nx, ny].G := CostG;
          Nodes[nx, ny].F := CostF;
        end;
      end;
    end;
  end;

  // 4. Rekonstruksi rute jika berhasil
  if PathFound then
  begin
    Result := TPathList.Create;
    CurrPos := TargetPos;

    // Trace back ke awal
    while not PosIsEqual(CurrPos, StartPos) do
    begin
      Result.Insert(0, CurrPos); // Masukkan di indeks 0 agar urut dari awal ke akhir

      nx := Nodes[CurrPos.X, CurrPos.Y].ParentX;
      ny := Nodes[CurrPos.X, CurrPos.Y].ParentY;

      CurrPos.X := nx;
      CurrPos.Y := ny;
    end;
  end;
end;

end.
