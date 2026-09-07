unit uStaffAI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Math, Graphics, uConstants, uSpriteManager;

type
  { TStaffAI: Entitas karyawan (Kasir) mandiri }
  TStaffAI = class
  public
    Pos: TPoint;
    DrawX, DrawY: Single;
    IsHired: Boolean;

    constructor Create;
    procedure Update(DeskX, DeskY: Integer);
    procedure Draw(ACanvas: TCanvas);
  end;

var
  KasirAI: TStaffAI; // Singleton Global (Mudah diakses)

implementation

constructor TStaffAI.Create;
begin
  IsHired := True;
  Pos := Point(-1, -1);
  DrawX := -1; DrawY := -1;
end;

procedure TStaffAI.Update(DeskX, DeskY: Integer);
begin
  if not IsHired then Exit;

  // Jika letak meja kasir ditemukan
  if (DeskX <> -1) and (DeskY <> -1) then
  begin
    // Kasir AI akan mencari titik di BELAKANG meja kasir (Y - 1)
    Pos := Point(DeskX, DeskY - 1);
  end;

  // Jika baru lahir, langsung teleport agar tidak bergeser dari pojok layar
  if (DrawX = -1) then
  begin
    DrawX := Pos.X;
    DrawY := Pos.Y;
  end;

  // Animasi Lerp (Mengejar meja kasir dengan mulus jika meja dipindah)
  DrawX := DrawX + (Pos.X - DrawX) * 0.15;
  DrawY := DrawY + (Pos.Y - DrawY) * 0.15;
end;

procedure TStaffAI.Draw(ACanvas: TCanvas);
var
  ScreenX, ScreenY, BobbingOffset: Integer;
begin
  if not IsHired or (Pos.X = -1) then Exit;

  ScreenX := Trunc(DrawX * TILE_SIZE);
  ScreenY := Trunc(DrawY * TILE_SIZE);

  // Efek pantulan langkah kaki (Bobbing)
  BobbingOffset := 0;
  if (Abs(Pos.X - DrawX) > 0.05) or (Abs(Pos.Y - DrawY) > 0.05) then
    BobbingOffset := Trunc(Abs(Sin(DrawX * 15 + DrawY * 15)) * 4);

  ScreenY := ScreenY - BobbingOffset;

  // Gambar Sprite Karyawan
  ACanvas.Draw(ScreenX, ScreenY, Sprites.BmpStaff);
end;

initialization
  KasirAI := TStaffAI.Create;
finalization
  if Assigned(KasirAI) then FreeAndNil(KasirAI);
end.
