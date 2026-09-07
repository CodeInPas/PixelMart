unit fStockMonitor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, ExtCtrls,
  uInventorySys, uGameTypes;

type
  { TStockMonitorForm }
  TStockMonitorForm = class(TForm)
    GridStock: TStringGrid;
    TimerRefresh: TTimer; // Mesin detak jantung pembaruan otomatis
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure TimerRefreshTimer(Sender: TObject);
  private
    FInventory: TInventoryManager;
  public
    procedure SetupData(AInv: TInventoryManager);
    procedure RefreshUI;
  end;

var
  StockMonitorForm: TStockMonitorForm;

implementation

{$R *.lfm}

procedure TStockMonitorForm.FormCreate(Sender: TObject);
begin
  // Setup Tabel
 // GridStock.Cells[0,0] := 'ID Produk';      GridStock.ColWidths[0] := 80;
  GridStock.Cells[0,0] := 'Nama Barang';    GridStock.ColWidths[0] := 180;
  GridStock.Cells[1,0] := 'Sisa Stok';      GridStock.ColWidths[1] := 100;
end;

procedure TStockMonitorForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  // Matikan timer saat jendela ditutup agar memori tidak bocor
  TimerRefresh.Enabled := False;
  CloseAction := caFree; // Hancurkan form dari RAM
  StockMonitorForm := nil; // Reset pointer agar bisa dibuka lagi nanti
end;

procedure TStockMonitorForm.SetupData(AInv: TInventoryManager);
begin
  FInventory := AInv;
  TimerRefresh.Enabled := True; // Nyalakan mesin pembaruan otomatis!
  RefreshUI;
end;

procedure TStockMonitorForm.TimerRefreshTimer(Sender: TObject);
begin
  // TTimer akan memicu prosedur ini secara otomatis setiap 500 milidetik (0,5 detik)
  RefreshUI;
end;

procedure TStockMonitorForm.RefreshUI;
var
  i, TotalQty, RowIdx: Integer;
  ProdID: String;
  Def: TProductDef;
begin
  if not Assigned(FInventory) then Exit;

  // Sesuaikan jumlah baris tabel dengan total jenis barang di database CSV
  GridStock.RowCount := FInventory.CatalogIDs.Count + 1;

  for i := 0 to FInventory.CatalogIDs.Count - 1 do
  begin
    ProdID := FInventory.CatalogIDs[i];

    if FInventory.GetProductDef(ProdID, Def) then
    begin
      // Menggunakan fungsi GetTotalStock yang mengkalkulasi fisik di rak secara akurat
      TotalQty := FInventory.GetTotalStock(ShortString(ProdID));
      RowIdx := i + 1;

     // GridStock.Cells[0, RowIdx] := ProdID;
      GridStock.Cells[0, RowIdx] := Def.Name;

      if TotalQty > 0 then
        GridStock.Cells[1, RowIdx] := IntToStr(TotalQty) + ' Pcs'
      else
        GridStock.Cells[1, RowIdx] := 'KOSONG!';
    end;
  end;
end;

end.
