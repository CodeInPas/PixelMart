unit fPricing;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, ExtCtrls, StdCtrls,
  uInventorySys, uGameTypes;

type
  { TPricingForm }
  TPricingForm = class(TForm)
    // Komponen sekarang berada di sini agar dikenali oleh Lazarus Visual Designer!
    GridPricing: TStringGrid;
    lblTitle: TLabel;
    lblHelp: TLabel;
    PanelTop: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure GridPricingDblClick(Sender: TObject);
  private
    FInventory: TInventoryManager;
  public
    procedure SetupData(AInv: TInventoryManager);
    procedure RefreshUI;
  end;

var
  PricingForm: TPricingForm;

implementation

{$R *.lfm}

procedure TPricingForm.FormCreate(Sender: TObject);
begin
  // Karena bentuk, warna, dan posisi sudah diatur di LFM,
  // FormCreate sekarang hanya fokus mengatur Teks Header Tabel saja.
  GridPricing.Cells[0,0] := 'ID Produk';      
  GridPricing.Cells[1,0] := 'Nama Barang';    
  GridPricing.Cells[2,0] := 'Harga Modal';    
  GridPricing.Cells[3,0] := 'Harga Jual';     
end;

procedure TPricingForm.SetupData(AInv: TInventoryManager);
begin
  FInventory := AInv;
  RefreshUI;
end;

procedure TPricingForm.RefreshUI;
var
  i, RowIdx: Integer;
  ProcessedIDs: TStringList;
  Item: TStockItem;
  Def: TProductDef;
begin
  ProcessedIDs := TStringList.Create;
  try
    GridPricing.RowCount := 1; // Bersihkan isi tabel, sisakan header

    // Pindai barang fisik yang ada di rak saat ini
    for i := 0 to FInventory.Stocks.Count - 1 do
    begin
      Item := FInventory.Stocks[i];

      // Filter agar 1 ID produk hanya tampil 1 baris (mengabaikan tumpukan batch)
      if ProcessedIDs.IndexOf(Item.ProductID) = -1 then
      begin
        ProcessedIDs.Add(Item.ProductID);

        if FInventory.GetProductDef(Item.ProductID, Def) then
        begin
          GridPricing.RowCount := GridPricing.RowCount + 1;
          RowIdx := GridPricing.RowCount - 1;

          GridPricing.Cells[0, RowIdx] := Item.ProductID;
          GridPricing.Cells[1, RowIdx] := Def.Name;
          GridPricing.Cells[2, RowIdx] := 'Rp ' + IntToStr(Def.BaseCost);
          GridPricing.Cells[3, RowIdx] := 'Rp ' + IntToStr(Item.SellPrice); 
        end;
      end;
    end;
  finally
    ProcessedIDs.Free;
  end;
end;

procedure TPricingForm.GridPricingDblClick(Sender: TObject);
var
  RowIdx, NewPrice: Integer;
  ProdID, CurrentPriceStr, NewPriceStr: String;
begin
  RowIdx := GridPricing.Row;
  if RowIdx < 1 then Exit;

  ProdID := GridPricing.Cells[0, RowIdx];
  // Bersihkan teks "Rp " agar menjadi angka murni
  CurrentPriceStr := StringReplace(GridPricing.Cells[3, RowIdx], 'Rp ', '', [rfReplaceAll]);

  // Munculkan jendela Input Dialog bawaan Windows
  NewPriceStr := InputBox('Ubah Harga Jual', 'Set harga jual baru untuk ' + ProdID + ':', CurrentPriceStr);

  if TryStrToInt(NewPriceStr, NewPrice) then
  begin
    if NewPrice > 0 then
    begin
      // Eksekusi fungsi perubahan harga di memori utama (uInventorySys)[cite: 6]
      FInventory.ChangeSellPrice(ShortString(ProdID), NewPrice);
      RefreshUI;
      ShowMessage('Sukses! Harga ' + ProdID + ' kini menjadi Rp ' + IntToStr(NewPrice));
    end;
  end;
end;

end.