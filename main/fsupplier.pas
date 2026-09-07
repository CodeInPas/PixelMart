unit fSupplier;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls, ExtCtrls,
  uConstants, uGameTypes, uInventorySys, uEconomyLogic;

type
  TSupplierForm = class(TForm)
    procedure FormCreate(Sender: TObject);
  private
    FInventory: TInventoryManager;
    FEconomy: TEconomyManager;

    // Komponen UI Dinamis (Dibuat otomatis oleh kode)
    PanelTop: TPanel;
    lblCash, lblHelp: TLabel;
    GridProducts: TStringGrid;

    procedure GridProductsDblClick(Sender: TObject);
  public
    procedure SetupData(AInv: TInventoryManager; AEco: TEconomyManager);
    procedure RefreshUI;
  end;

var
  SupplierForm: TSupplierForm;

implementation

{$R *.lfm} // Wajib ada agar Lazarus tidak error

procedure TSupplierForm.FormCreate(Sender: TObject);
begin
  Caption := 'Distributor & Supplier (Kulakan)';
  Width := 500;
  Height := 300;
  Position := poMainFormCenter;

  // 1. Buat Panel Atas untuk Info Uang
  PanelTop := TPanel.Create(Self);
  PanelTop.Parent := Self;
  PanelTop.Align := alTop;
  PanelTop.Height := 60;

  lblCash := TLabel.Create(Self);
  lblCash.Parent := PanelTop;
  lblCash.Align := alTop;
  lblCash.Alignment := taCenter;
  lblCash.Font.Size := 14;
  lblCash.Font.Style := [fsBold];
  lblCash.Caption := 'Uang Kas: -';

  lblHelp := TLabel.Create(Self);
  lblHelp.Parent := PanelTop;
  lblHelp.Align := alBottom;
  lblHelp.Alignment := taCenter;
  lblHelp.Font.Color := clBlue;
  lblHelp.Caption := 'KLIK GANDA (Double-Click) pada baris barang untuk Kulakan 1 Karton (Isi 10)';

  // 2. Buat Tabel Data Barang (StringGrid)
  GridProducts := TStringGrid.Create(Self);
  GridProducts.Parent := Self;
  GridProducts.Align := alClient;
  GridProducts.FixedCols := 0;
  GridProducts.ColCount := 4;
  GridProducts.RowCount := 4; // 1 Header + 3 Produk Dasar
  GridProducts.Options := GridProducts.Options + [goRowSelect];
  GridProducts.OnDblClick := @GridProductsDblClick;

  // Setup Header Tabel
  GridProducts.Cells[0,0] := 'ID Barang';    GridProducts.ColWidths[0] := 80;
  GridProducts.Cells[1,0] := 'Nama Produk';  GridProducts.ColWidths[1] := 150;
  GridProducts.Cells[2,0] := 'Harga Modal';  GridProducts.ColWidths[2] := 110;
  GridProducts.Cells[3,0] := 'Umur Simpan';  GridProducts.ColWidths[3] := 100;
end;

procedure TSupplierForm.SetupData(AInv: TInventoryManager; AEco: TEconomyManager);
begin
  FInventory := AInv;
  FEconomy := AEco;
  RefreshUI;
end;

procedure TSupplierForm.RefreshUI;
var
  Def: TProductDef;
begin
  lblCash.Caption := Format('Sisa Uang Kas: Rp %g', [FEconomy.Cash * 1.0]);

  // Render 3 Barang Dasar ke dalam Grid
  if FInventory.GetProductDef('BRS-01', Def) then
  begin
    GridProducts.Cells[0,1] := Def.ProductID;
    GridProducts.Cells[1,1] := 'Sembako Dasar';
    GridProducts.Cells[2,1] := 'Rp ' + IntToStr(Def.BaseCost);
    GridProducts.Cells[3,1] := IntToStr(Def.BaseExpiry) + ' Hari';
  end;

  if FInventory.GetProductDef('MIE-01', Def) then
  begin
    GridProducts.Cells[0,2] := Def.ProductID;
    GridProducts.Cells[1,2] := 'Mie Instan';
    GridProducts.Cells[2,2] := 'Rp ' + IntToStr(Def.BaseCost);
    GridProducts.Cells[3,2] := IntToStr(Def.BaseExpiry) + ' Hari';
  end;

  if FInventory.GetProductDef('MIN-01', Def) then
  begin
    GridProducts.Cells[0,3] := Def.ProductID;
    GridProducts.Cells[1,3] := 'Minuman Segar';
    GridProducts.Cells[2,3] := 'Rp ' + IntToStr(Def.BaseCost);
    GridProducts.Cells[3,3] := IntToStr(Def.BaseExpiry) + ' Hari';
  end;
end;

procedure TSupplierForm.GridProductsDblClick(Sender: TObject);
var
  RowIdx: Integer;
  ProdID: String;
  Def: TProductDef;
  Cost: Int64;
  QtyBuy: Integer;
  NewItem: TStockItem;
begin
  RowIdx := GridProducts.Row;
  if RowIdx < 1 then Exit; // Abaikan jika mengklik Header

  ProdID := GridProducts.Cells[0, RowIdx];
  if not FInventory.GetProductDef(ProdID, Def) then Exit;

  QtyBuy := 10; // 1 Karton = 10 Pcs
  Cost := Def.BaseCost * QtyBuy;

  // Cek konfirmasi dan potong uang kas
  if MessageDlg('Konfirmasi Pembelian',
                Format('Beli 1 Karton (10 pcs) %s seharga Rp %d?', [ProdID, Cost]),
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    if FEconomy.DeductCash(Cost) then
    begin
      NewItem.ProductID := Def.ProductID;
      NewItem.Qty := QtyBuy;
      NewItem.SellPrice := Def.BaseCost + 5000; // Markup keuntungan Rp 5.000 per pcs
      NewItem.DaysToExpiry := Def.BaseExpiry;

      FInventory.Stocks.Add(NewItem); // Masukkan barang ke rak
      ShowMessage('Sukses! Barang langsung dikirim ke rak toko.');
      RefreshUI;
    end
    else
      ShowMessage('Gagal: Uang kas Anda tidak mencukupi!');
  end;
end;

end.
