unit uDoubleBuffer;
{$mode objfpc}{$H+}
{$INLINE ON}
{$OPTIMIZATION LEVEL3}

interface

uses
  Classes, Graphics, Types, uConstants;

type
  { TDoubleBuffer
    Mengelola off-screen bitmap raksasa di memori RAM untuk mencegah flickering. }
  TDoubleBuffer = class
  private
    FBuffer: TBitmap;
    FWidth: Integer;
    FHeight: Integer;
    FBackColor: TColor;

    function GetCanvas: TCanvas; inline;
  public
    constructor Create(AWidth, AHeight: Integer; ABackColor: TColor);
    destructor Destroy; override;

    { Membersihkan kanvas memori dengan warna dasar lantai/background }
    procedure Clear; inline;

    { Menyalin secara sinkron (Blitting) seluruh frame dari RAM ke Canvas TPaintBox }
    procedure Flip(ADestCanvas: TCanvas; AX: Integer = 0; AY: Integer = 0); inline;

    { Mengubah ukuran buffer tanpa mengalokasikan ulang objek }
    procedure Resize(ANewWidth, ANewHeight: Integer);

    property Canvas: TCanvas read GetCanvas;
    property Buffer: TBitmap read FBuffer;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property BackColor: TColor read FBackColor write FBackColor;
  end;

implementation

constructor TDoubleBuffer.Create(AWidth, AHeight: Integer; ABackColor: TColor);
begin
  FWidth := AWidth;
  FHeight := AHeight;
  FBackColor := ABackColor;

  FBuffer := TBitmap.Create;

  // pf32bit memaksa penempatan memori yang selaras dengan arsitektur OS modern,
  // melewati bottleneck konversi palet warna saat proses draw/blit.
  FBuffer.PixelFormat := pf32bit;
  FBuffer.SetSize(FWidth, FHeight);
end;

destructor TDoubleBuffer.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

function TDoubleBuffer.GetCanvas: TCanvas; inline;
begin
  Result := FBuffer.Canvas;
end;

procedure TDoubleBuffer.Clear; inline;
begin
  FBuffer.Canvas.Brush.Style := bsSolid;
  FBuffer.Canvas.Brush.Color := FBackColor;
  // FillRect menggunakan panggilan level rendah GDI/X11 untuk performa pewarnaan blok instan
  FBuffer.Canvas.FillRect(Rect(0, 0, FWidth, FHeight));
end;

procedure TDoubleBuffer.Flip(ADestCanvas: TCanvas; AX: Integer = 0; AY: Integer = 0); inline;
begin
  // Transfer 1:1 tercepat yang didukung native LCL
  ADestCanvas.Draw(AX, AY, FBuffer);
end;

procedure TDoubleBuffer.Resize(ANewWidth, ANewHeight: Integer);
begin
  if (FWidth <> ANewWidth) or (FHeight <> ANewHeight) then
  begin
    FWidth := ANewWidth;
    FHeight := ANewHeight;
    FBuffer.SetSize(FWidth, FHeight);
  end;
end;

end.

