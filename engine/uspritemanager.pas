unit uSpriteManager;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Dialogs;

type
  TSpriteManager = class
  public
    BmpFloor: TBitmap;
    BmpRack: TBitmap;
    BmpCashier: TBitmap;
    BmpDoor: TBitmap;
    BmpCustomer: TBitmap;
    BmpStaff: TBitmap; // --> BARU: Sprite Kasir

    constructor Create;
    destructor Destroy; override;
  private
    procedure LoadOrGenerateSprite(var ABmp: TBitmap; const AFileName: String; AType: String);
    procedure DrawPlaceholder(ABmp: TBitmap; AType: String);
  end;

var
  Sprites: TSpriteManager;

implementation

constructor TSpriteManager.Create;
var
  AppPath, AssetDir: String;
begin
  AppPath := ExtractFilePath(ParamStr(0));
  AssetDir := ExpandFileName(AppPath + 'assets\');

  if not DirectoryExists(AssetDir) then ForceDirectories(AssetDir);

  BmpFloor := TBitmap.Create;
  BmpRack := TBitmap.Create;
  BmpCashier := TBitmap.Create;
  BmpDoor := TBitmap.Create;
  BmpCustomer := TBitmap.Create;
  BmpStaff := TBitmap.Create;

  LoadOrGenerateSprite(BmpFloor, AssetDir + 'floor.bmp', 'FLOOR');
  LoadOrGenerateSprite(BmpRack, AssetDir + 'rack.bmp', 'RACK');
  LoadOrGenerateSprite(BmpCashier, AssetDir + 'cashier.bmp', 'CASHIER');
  LoadOrGenerateSprite(BmpDoor, AssetDir + 'door.bmp', 'DOOR');
  LoadOrGenerateSprite(BmpCustomer, AssetDir + 'customer.bmp', 'CUSTOMER');
  LoadOrGenerateSprite(BmpStaff, AssetDir + 'staff.bmp', 'STAFF'); // --> Generate Staff
end;

destructor TSpriteManager.Destroy;
begin
  BmpFloor.Free; BmpRack.Free; BmpCashier.Free;
  BmpDoor.Free; BmpCustomer.Free; BmpStaff.Free;
  inherited Destroy;
end;

procedure TSpriteManager.DrawPlaceholder(ABmp: TBitmap; AType: String);
var
  TS: Integer;
begin
  TS := 32;
  ABmp.Width := TS; ABmp.Height := TS;
  ABmp.Canvas.Brush.Color := clFuchsia;
  ABmp.Canvas.FillRect(0, 0, TS, TS);
  ABmp.TransparentColor := clFuchsia;
  ABmp.Transparent := True;

  if AType = 'FLOOR' then
  begin
    ABmp.Canvas.Brush.Color := $00E0E0E0;
    ABmp.Canvas.FillRect(0, 0, TS, TS);
    ABmp.Canvas.Pen.Color := clSilver;
    ABmp.Canvas.Rectangle(0, 0, TS, TS);
  end
  else if AType = 'RACK' then
  begin
    ABmp.Canvas.Brush.Color := $004080FF;
    ABmp.Canvas.FillRect(2, 2, TS-2, TS-2);
    ABmp.Canvas.Pen.Color := clBlack;
    ABmp.Canvas.MoveTo(2, TS div 2); ABmp.Canvas.LineTo(TS-2, TS div 2);
  end
  else if AType = 'CASHIER' then
  begin
    ABmp.Canvas.Brush.Color := clBlue;
    ABmp.Canvas.FillRect(0, TS div 2, TS, TS);
    ABmp.Canvas.Brush.Color := clWhite;
    ABmp.Canvas.FillRect(TS div 4, TS div 4, TS - (TS div 4), TS div 2);
  end
  else if AType = 'DOOR' then
  begin
    ABmp.Canvas.Brush.Color := clLime;
    ABmp.Canvas.FillRect(0, 0, TS, TS);
    ABmp.Canvas.Brush.Color := clGreen;
    ABmp.Canvas.FillRect(TS div 4, 0, TS - (TS div 4), TS);
  end
  else if AType = 'CUSTOMER' then
  begin
    ABmp.Canvas.Brush.Color := clYellow;
    ABmp.Canvas.Pen.Color := clRed;
    ABmp.Canvas.Ellipse(4, 4, TS-4, TS-4);
    ABmp.Canvas.Brush.Color := clBlack;
    ABmp.Canvas.FillRect(10, 10, 14, 14); ABmp.Canvas.FillRect(18, 10, 22, 14);
  end
  else if AType = 'STAFF' then
  begin
    // --> Gambar Karyawan: Seragam Biru Muda, Topi Merah
    ABmp.Canvas.Brush.Color := clAqua;
    ABmp.Canvas.Pen.Color := clBlue;
    ABmp.Canvas.Ellipse(4, 4, TS-4, TS-4);
    ABmp.Canvas.Brush.Color := clRed;
    ABmp.Canvas.FillRect(6, 2, TS-6, 10); // Topi
    ABmp.Canvas.Brush.Color := clBlack;
    ABmp.Canvas.FillRect(10, 12, 14, 16); ABmp.Canvas.FillRect(18, 12, 22, 16); // Mata
  end;
end;

procedure TSpriteManager.LoadOrGenerateSprite(var ABmp: TBitmap; const AFileName: String; AType: String);
begin
  if FileExists(AFileName) then
  begin
    ABmp.LoadFromFile(AFileName);
    ABmp.TransparentColor := clFuchsia;
    ABmp.Transparent := True;
  end
  else
  begin
    DrawPlaceholder(ABmp, AType);
    ABmp.SaveToFile(AFileName);
  end;
end;

initialization
  Sprites := TSpriteManager.Create;
finalization
  if Assigned(Sprites) then
    FreeAndNil(Sprites);
end.
