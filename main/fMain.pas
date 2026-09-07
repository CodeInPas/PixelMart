unit fMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Menus, uConstants, uGameTypes, uGameLoop, fstock, fSummary, fLedger, fPricing,
  fStockMonitor;

type

  { TMainForm }

  TMainForm = class(TForm)
    btnAction: TButton;
    btnStock: TButton;
    btnledger: TButton;
    btnpricing: TButton;
    btnLiveMonitor: TButton;
    lblStatus: TLabel;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem3: TMenuItem;
    mnExit: TMenuItem;
    MenuItem9: TMenuItem;
    pnStock: TPanel;
    pnlUI: TPanel;
    pbScreen: TPaintBox;
    Separator1: TMenuItem;

    procedure btnActionClick(Sender: TObject);
    procedure btnledgerClick(Sender: TObject);
    procedure btnpricingClick(Sender: TObject);
    procedure btnStockClick(Sender: TObject);
    procedure btnLiveMonitorClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MenuItem10Click(Sender: TObject);
    procedure mnExitClick(Sender: TObject);
    procedure pbScreenPaint(Sender: TObject);

    // --> EVENT BARU: Deteksi Klik Mouse di Layar
    procedure pbScreenMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    FGameLoop: TGameLoop;
    rgBuildMode: TRadioGroup; // --> UI Dinamis untuk Mode Bangun
    procedure UpdateUIState;
    procedure GeneratePlaceholderSprites;
    procedure OnGameStateChanged(NewState: Integer);
    procedure MoveUniqueTile(ATile: TTileType; NewX, NewY: Integer); // --> Helper Pindah Letak
  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
var
  SavePath : String;
begin

  Self.ClientWidth := VIEWPORT_WIDTH + 270;
  Self.ClientHeight := VIEWPORT_HEIGHT;
  Self.Position := poScreenCenter;
  Self.Caption := 'PixelMart : Simulator Warung Harian';
  Self.BorderStyle := bsSingle;

  FGameLoop := TGameLoop.Create(pbScreen);
  FGameLoop.OnStateChanged := @OnGameStateChanged;

  // --> INJEKSI UI: Auto-Generate Opsi Mode Bangun
  rgBuildMode := TRadioGroup.Create(Self);
  rgBuildMode.Parent := pnlUI; // Tempel di panel menu kanan
  rgBuildMode.Align := alBottom;
  rgBuildMode.Height := 105;
  rgBuildMode.Caption := 'Mode Tata Letak';
  rgBuildMode.Items.Add('Beli Rak (Rp 250rb)');
  rgBuildMode.Items.Add('Pindah Kasir');
  rgBuildMode.Items.Add('Pindah Pintu');
  rgBuildMode.ItemIndex := 0;
  rgBuildMode.Font.Style := [fsBold];
  rgBuildMode.BorderSpacing.Around:=8;
  rgBuildMode.Font.Color:=clWhite;
  rgBuildMode.Visible:=false;

  // --> AUTO-LOAD SAAT GAME DIBUKA
  SavePath := ExtractFilePath(ParamStr(0)) + 'savegame.ini';
  if FGameLoop.LoadGame(SavePath) then
    ShowMessage('Progres warung sebelumnya berhasil dimuat!');

  btnLiveMonitorClick(sender);
 UpdateUIState;
 // GeneratePlaceholderSprites
end;

procedure TMainForm.OnGameStateChanged(NewState: Integer);
var
  SummaryDialog: TSummaryForm;
begin
  UpdateUIState;
  pnlUI.Color:=RGBToColor(100,150,129);
  // Jika Engine berubah ke STATE_SUMMARY (Malam Hari), paksa munculkan Pop-up
  if NewState = STATE_SUMMARY then
  begin
    SummaryDialog := TSummaryForm.CreateWithEngine(Self, FGameLoop.Economy);
    try
      SummaryDialog.ShowModal; // Game akan terjeda menunggu pemain klik "Mulai Hari Esok"
    finally
      SummaryDialog.Free;
      // Setelah popup ditutup, otomatis pindah ke fase Pagi (PREP)
      FGameLoop.ChangeState(STATE_PREP);
    end;
  end;
end;

procedure TMainForm.GeneratePlaceholderSprites;
var
  Bmp: TBitmap;
  SavePath: String;
begin
  // Tentukan path folder assets/gfx di sebelah file EXE
  SavePath := ExtractFilePath(ParamStr(0)) + 'assets' + DirectorySeparator + 'gfx' + DirectorySeparator;

  // Buat foldernya jika belum ada
  ForceDirectories(SavePath);

  Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf32bit;
    Bmp.SetSize(32, 32); // Ukuran standar Tile kita

    // 1. Buat spr_floor.bmp (Abu-abu Lantai)
    Bmp.Canvas.Brush.Color := $00C0C0C0; // clSilver
    Bmp.Canvas.FillRect(0, 0, 32, 32);
    // Tambahkan motif garis kotak-kotak tipis agar seperti keramik
    Bmp.Canvas.Pen.Color := $00A0A0A0;
    Bmp.Canvas.Rectangle(0, 0, 32, 32);
    Bmp.SaveToFile(SavePath + 'spr_floor.bmp');

    // 2. Buat spr_wall.bmp (Abu-abu Gelap Tembok)
    Bmp.Canvas.Brush.Color := $00404040;
    Bmp.Canvas.FillRect(0, 0, 32, 32);
    Bmp.SaveToFile(SavePath + 'spr_wall.bmp');

    // 3. Buat spr_npc_walk.bmp (Karakter Biru dengan background Magenta)
    Bmp.Canvas.Brush.Color := clFuchsia; // Background transparan
    Bmp.Canvas.FillRect(0, 0, 32, 32);
    Bmp.Canvas.Brush.Color := $006699FF; // Warna Karakter
    Bmp.Canvas.Ellipse(4, 4, 28, 28);
    Bmp.SaveToFile(SavePath + 'spr_npc_walk.bmp');

    ShowMessage('File BMP berhasil dibuat di: ' + SavePath);
  finally
    Bmp.Free;
  end;
end;


procedure TMainForm.FormDestroy(Sender: TObject);
var
SavePath: String;
begin

  Application.ProcessMessages;

  if Assigned(FGameLoop) then
  begin
  // --> AUTO-SAVE SAAT GAME DITUTUP
    SavePath := ExtractFilePath(ParamStr(0)) + 'savegame.ini';
    FGameLoop.SaveGame(SavePath);

    FGameLoop.Free;
    FGameLoop := nil; // Putuskan rantai pointer ke memori yang mati
  end;

  Application.Terminate;



end;

procedure TMainForm.MenuItem10Click(Sender: TObject);
begin
  ShowMessage('PixelMart v0.1 ' + #13 + 'Simulasi Warung Kelontong');
end;

procedure TMainForm.mnExitClick(Sender: TObject);
begin
  Application.Terminate ;
end;

procedure TMainForm.btnActionClick(Sender: TObject);
begin
  if not Assigned(FGameLoop) then Exit;

  case FGameLoop.GameState of
    STATE_PREP: FGameLoop.ChangeState(STATE_OPEN);
    STATE_SUMMARY: FGameLoop.ChangeState(STATE_PREP);
  end;

  UpdateUIState;
end;

procedure TMainForm.btnLedgerClick(Sender: TObject);
var
  LedgerDialog: TLedgerForm;
begin
  if not Assigned(FGameLoop) then Exit;

  LedgerDialog := TLedgerForm.CreateWithEngine(Self, FGameLoop.Economy);
  try
    LedgerDialog.ShowModal;
  finally
    LedgerDialog.Free;
  end;
end;


  procedure TMainForm.btnPricingClick(Sender: TObject);
var
  FrmPricing: TPricingForm;
begin
  if not Assigned(FGameLoop) then Exit;

  FrmPricing := TPricingForm.Create(Self);
  try
    // Berikan akses penuh ke data Inventori
    FrmPricing.SetupData(FGameLoop.Inventory);
    FrmPricing.ShowModal;
  finally
    FrmPricing.Free;
  end;
end;


procedure TMainForm.btnStockClick(Sender: TObject);
var
  StockDialog: TStockForm;
begin
  if not Assigned(FGameLoop) then Exit;

  if FGameLoop.GameState <> STATE_PREP then
  begin
    ShowMessage('Kulakan barang hanya bisa dilakukan di Pagi Hari (Fase Persiapan)!');
    Exit;
  end;

  // Instansiasi form baru dengan menginjeksi mesin yang sama
  StockDialog := TStockForm.CreateWithEngine(Self, FGameLoop.Inventory, FGameLoop.Economy);
  try
    StockDialog.Position := poMainFormCenter;
    StockDialog.Caption := 'Supplier Warung (Grosir)';
    StockDialog.ShowModal; // Membuka form secara memblokir (Modal)
  finally
    StockDialog.Free; // Cegah memory leak setelah ditutup
    UpdateUIState;    // Refresh teks uang di form utama
  end;
end;

procedure TMainForm.btnLiveMonitorClick(Sender: TObject);
begin

  StockMonitorForm := TStockMonitorForm.Create(Application);
  StockMonitorForm.Parent:=pnStock;
  StockMonitorForm.BorderStyle:=bsnone;
  StockMonitorForm.Align:=alClient;
  StockMonitorForm.SetupData(FGameLoop.Inventory);
  StockMonitorForm.Show;
  {
  if not Assigned(FGameLoop) then Exit;

  // Cek apakah jendela sudah terbuka agar tidak menumpuk banyak jendela yang sama
  if not Assigned(StockMonitorForm) then
  begin
    StockMonitorForm := TStockMonitorForm.Create(Application);
    StockMonitorForm.SetupData(FGameLoop.Inventory);
  end;

  // =============================================================
  // RAHASIA REAL-TIME: Gunakan .Show (Bukan .ShowModal)
  // Ini memungkinkan jendela melayang sambil game tetap berputar!
  // =============================================================
  StockMonitorForm.Show;
}
end;

procedure TMainForm.pbScreenPaint(Sender: TObject);
begin
  // Fallback paint event
end;

procedure TMainForm.pbScreenMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  GridX, GridY: Integer;
  Cell: PGridCell;
  Cost: Int64;
begin
  if not Assigned(FGameLoop) then Exit;
  if FGameLoop.GameState <> STATE_PREP then
  begin
    ShowMessage('Anda hanya bisa menata warung pada Fase Pagi hari!');
    Exit;
  end;

  GridX := X div TILE_SIZE;
  GridY := Y div TILE_SIZE;

  // Failsafe: Cegah klik di luar batas Grid
  if (GridX < 0) or (GridX >= GRID_COLS) or (GridY < 0) or (GridY >= GRID_ROWS) then Exit;

  Cell := FGameLoop.Grid.GetCellPtr(GridX, GridY);
  if Cell = nil then Exit;

  if Button = mbLeft then
  begin
    if Cell^.TileType = ttFloor then
    begin
      // --> CEK MODE APA YANG SEDANG DIPILIH PEMAIN
      case rgBuildMode.ItemIndex of
        0: // Mode Beli Rak
          begin
            Cost := 250000;
            if FGameLoop.Economy.DeductCash(Cost) then
              FGameLoop.Grid.SetTile(GridX, GridY, ttRack)
            else
              ShowMessage('Kas tidak mencukupi untuk membeli Rak! (Harga: Rp 250.000)');
          end;
        1: // Mode Pindah Kasir
          begin
            // Proteksi Antrean: Kasir tidak boleh di ujung kiri (X=0)
            if GridX = 0 then
            begin
              ShowMessage('Kasir tidak bisa diletakkan di batas paling kiri layar. Sisakan ruang untuk antrean pelanggan!');
              Exit;
            end;
            MoveUniqueTile(ttCashier, GridX, GridY);
          end;
        2: // Mode Pindah Pintu
          begin
            MoveUniqueTile(ttDoor, GridX, GridY);
          end;
      end;
    end
    else
    begin
       ShowMessage('Pilih lantai kosong (warna abu-abu) untuk memindahkan objek!');
    end;
  end
  else if Button = mbRight then
  begin
    if Cell^.TileType = ttRack then
    begin
      Cost := 125000; // Uang kembali setengah harga
      FGameLoop.Economy.AddCash(Cost);
      FGameLoop.Grid.SetTile(GridX, GridY, ttFloor);
    end;
  end;
end;

procedure TMainForm.UpdateUIState;
begin
  if not Assigned(FGameLoop) then Exit;

  case FGameLoop.GameState of
    STATE_PREP:
      begin
        lblStatus.Caption := 'Fase: Pagi (Persiapan)';
        btnAction.Caption := 'Buka Warung!';
        btnAction.Enabled := True;
      end;

    STATE_OPEN:
      begin
        lblStatus.Caption := 'Fase: Siang (Operasional)';
        btnAction.Caption := 'Warung Sedang Buka...';
        btnAction.Enabled := False;
      end;

    STATE_SUMMARY:
      begin
        lblStatus.Caption := 'Fase: Malam (Rekap)';
        btnAction.Caption := 'Mulai Hari Esok';
        btnAction.Enabled := True;
      end;

    STATE_GAMEOVER:
      begin
        lblStatus.Caption := 'BANGKRUT!';
        btnAction.Caption := 'Game Over';
        btnAction.Enabled := False;
      end;
  end;
end;
procedure TMainForm.MoveUniqueTile(ATile: TTileType; NewX, NewY: Integer);
var
  x, y: Integer;
  Cell: PGridCell;
begin
  // 1. Hapus tile yang lama (Ubah kembali jadi lantai kosong)
  for x := 0 to GRID_COLS - 1 do
  begin
    for y := 0 to GRID_ROWS - 1 do
    begin
      Cell := FGameLoop.Grid.GetCellPtr(x, y);
      if Cell^.TileType = ATile then
        FGameLoop.Grid.SetTile(x, y, ttFloor);
    end;
  end;
  // 2. Pasang di tempat yang baru
  FGameLoop.Grid.SetTile(NewX, NewY, ATile);
end;


end.
