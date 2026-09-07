unit fstock;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Grids,
  StdCtrls, uConstants, uGameTypes, uInventorySys, uEconomyLogic;

type

  { TStockForm }

  TStockForm = class(TForm)
    btnBuy: TButton;
    btnClose: TButton;
    lblCash: TLabel;
    pnlBottom: TPanel;
    sgProducts: TStringGrid;

    procedure btnBuyClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FInventory: TInventoryManager;
    FEconomy: TEconomyManager;

    procedure RefreshUI;
  public
    // Custom constructor untuk menyuntikkan dependensi Engine
    constructor CreateWithEngine(AOwner: TComponent; AInv: TInventoryManager; AEco: TEconomyManager);
  end;

var
  StockForm: TStockForm;

implementation

{$R *.lfm}

{ TStockForm }

constructor TStockForm.CreateWithEngine(AOwner: TComponent; AInv: TInventoryManager; AEco: TEconomyManager);
begin
  inherited Create(AOwner);
  FInventory := AInv;
  FEconomy := AEco;
end;

procedure TStockForm.FormShow(Sender: TObject);
var
  i: Integer;
  Def: TProductDef;
begin
  // Setup Grid Kolom & Baris
  sgProducts.ColCount := 5;
  sgProducts.RowCount := FInventory.MasterProducts.Count + 1; // +1 untuk Header

  // Setup Header Grid
  sgProducts.Cells[0, 0] := 'ID Produk';
  sgProducts.Cells[1, 0] := 'Nama Barang';
  sgProducts.Cells[2, 0] := 'Kategori';
  sgProducts.Cells[3, 0] := 'Harga Modal';
  sgProducts.Cells[4, 0] := 'Kedaluwarsa';

  // O(N) Iterasi dari Generics Map ke TStringGrid
  for i := 0 to FInventory.MasterProducts.Count - 1 do
  begin
    Def := FInventory.MasterProducts.Data[i];
    sgProducts.Cells[0, i + 1] := Def.ID;
    sgProducts.Cells[1, i + 1] := Def.Name;

    case Def.Category of
      pcStaple:   sgProducts.Cells[2, i + 1] := 'Sembako';
      pcSnack:    sgProducts.Cells[2, i + 1] := 'Jajanan/Minuman';
      pcTertiary: sgProducts.Cells[2, i + 1] := 'Tersier';
    end;

    sgProducts.Cells[3, i + 1] := 'Rp ' + IntToStr(Def.BaseCost);

    if Def.MaxExpiry = 0 then
      sgProducts.Cells[4, i + 1] := 'Awet'
    else
      sgProducts.Cells[4, i + 1] := IntToStr(Def.MaxExpiry) + ' Hari';
  end;

  // Auto-resize lebar kolom
  sgProducts.AutoSizeColumns;
  RefreshUI;
end;

procedure TStockForm.RefreshUI;
begin
  lblCash.Caption := 'Sisa Kas Uang: Rp ' + IntToStr(FEconomy.Cash);
end;

procedure TStockForm.btnBuyClick(Sender: TObject);
var
  SelRow: Integer;
  ProductID: String;
  Def: TProductDef;
  TotalCost: Int64;
  BatchQty: Integer;
  SellPrice: Integer;
begin
  SelRow := sgProducts.Row;
  if SelRow < 1 then Exit; // Mengabaikan jika yang diklik adalah Header

  ProductID := sgProducts.Cells[0, SelRow];
  BatchQty := 10; // Secara default, kulakan barang selalu per 10 pcs (1 Batch)

  if FInventory.GetProductDef(ProductID, Def) then
  begin
    TotalCost := Def.BaseCost * BatchQty;

    // Cek apakah uang cukup
    if FEconomy.DeductCash(TotalCost) then
    begin
      // Tentukan Harga Jual Default (Mark-up 30%)
      SellPrice := Trunc(Def.BaseCost * 1.3);

      // Masukkan ke inventori
      FInventory.AddStock(ProductID, BatchQty, SellPrice);

      ShowMessage(Format('Berhasil membeli 10 pcs %s!'#13#10'Otomatis dipajang dengan harga jual Rp %d', [Def.Name, SellPrice]));
      RefreshUI;
    end
    else
    begin
      ShowMessage('Kas Anda tidak cukup untuk membeli batch barang ini!');
    end;
  end;
end;

procedure TStockForm.btnCloseClick(Sender: TObject);
begin
  Self.ModalResult := mrOk; // Menutup form dialog
end;

end.
