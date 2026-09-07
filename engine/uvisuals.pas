unit uVisuals;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, uConstants;

type
  { Struktur data untuk satu partikel teks }
  TFloatingText = record
    Text: String;
    X, Y: Single;
    LifeSpan: Integer;
    Color: TColor;
  end;

  { Mesin pengelola seluruh efek visual }
  TVisualFXManager = class
  private
    FParticles: array of TFloatingText;
  public
    constructor Create;
    destructor Destroy; override;

    procedure SpawnText(AText: String; AX, AY: Single; AColor: TColor);
    procedure Update;
    procedure Draw(ACanvas: TCanvas);
  end;

var
  // Variabel global agar AI bisa dengan mudah memicu efek
  FXManager: TVisualFXManager;

implementation

constructor TVisualFXManager.Create;
begin
  SetLength(FParticles, 0);
end;

destructor TVisualFXManager.Destroy;
begin
  SetLength(FParticles, 0);
  inherited Destroy;
end;

procedure TVisualFXManager.SpawnText(AText: String; AX, AY: Single; AColor: TColor);
var
  L: Integer;
begin
  L := Length(FParticles);
  SetLength(FParticles, L + 1);
  FParticles[L].Text := AText;
  FParticles[L].X := AX;
  FParticles[L].Y := AY;
  FParticles[L].LifeSpan := 30; // Bertahan selama ~30 frame (1 detik)
  FParticles[L].Color := AColor;
end;

procedure TVisualFXManager.Update;
var
  i, j: Integer;
begin
  // Loop terbalik karena kita akan menghapus elemen dari array
  for i := Length(FParticles) - 1 downto 0 do
  begin
    Dec(FParticles[i].LifeSpan);

    // Gerakkan teks ke atas secara perlahan (Y minus)
    FParticles[i].Y := FParticles[i].Y - 0.05;

    // Jika umur habis, hapus dari array
    if FParticles[i].LifeSpan <= 0 then
    begin
      for j := i to Length(FParticles) - 2 do
        FParticles[j] := FParticles[j + 1];
      SetLength(FParticles, Length(FParticles) - 1);
    end;
  end;
end;

procedure TVisualFXManager.Draw(ACanvas: TCanvas);
var
  i: Integer;
  ScreenX, ScreenY: Integer;
begin
  ACanvas.Brush.Style := bsClear; // Teks dengan latar transparan
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Size := 11;

  for i := 0 to High(FParticles) do
  begin
    ACanvas.Font.Color := FParticles[i].Color;

    // Konversi posisi Float (Grid) ke Posisi Pixel (Layar)
    ScreenX := Trunc(FParticles[i].X * TILE_SIZE);
    ScreenY := Trunc(FParticles[i].Y * TILE_SIZE);

    // Gambar teks di kanvas
    ACanvas.TextOut(ScreenX, ScreenY, FParticles[i].Text);
  end;

  ACanvas.Brush.Style := bsSolid; // Kembalikan ke normal
end;

initialization
  FXManager := TVisualFXManager.Create;
finalization
  FXManager.Free;
end.
