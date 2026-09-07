unit fLedger;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, ExtCtrls, StdCtrls,
  uEconomyLogic;

type
  { TLedgerForm }
  TLedgerForm = class(TForm)
    GridLedger: TStringGrid;
    pnlTop: TPanel;
    lblTitle: TLabel;
  private
    FEconomy: TEconomyManager;
  public
    constructor CreateWithEngine(AOwner: TComponent; AEco: TEconomyManager);
    procedure LoadData;
  end;

implementation

{$R *.lfm}

constructor TLedgerForm.CreateWithEngine(AOwner: TComponent; AEco: TEconomyManager);
begin
  inherited Create(AOwner);
  FEconomy := AEco;
  LoadData;
end;

procedure TLedgerForm.LoadData;
var
  i, RowIdx: Integer;
  Rep: TDailyReport;
  MarginRatio: Single;
begin
  // 1. Konfigurasi Visual StringGrid (Via Kode agar praktis)
  GridLedger.FixedCols := 0;
  GridLedger.Options := GridLedger.Options + [goRowSelect];
  GridLedger.ColCount := 7;

  // PERBAIKAN 1: Menggunakan Length() untuk Array
  GridLedger.RowCount := Length(FEconomy.History) + 1;
  if GridLedger.RowCount < 2 then GridLedger.RowCount := 2;

  // 2. Setup Header Kolom & Lebar
  GridLedger.Cells[0, 0] := 'Hari Ke-';     GridLedger.ColWidths[0] := 60;
  GridLedger.Cells[1, 0] := 'Omzet Bruto';  GridLedger.ColWidths[1] := 110;
  GridLedger.Cells[2, 0] := 'Beban Opr.';   GridLedger.ColWidths[2] := 100;
  GridLedger.Cells[3, 0] := 'Penyusutan';   GridLedger.ColWidths[3] := 90;
  GridLedger.Cells[4, 0] := 'Pajak (0.5%)'; GridLedger.ColWidths[4] := 90;
  GridLedger.Cells[5, 0] := 'Laba Bersih';  GridLedger.ColWidths[5] := 110;
  GridLedger.Cells[6, 0] := 'Margin (%)';   GridLedger.ColWidths[6] := 80;

  // PERBAIKAN 2: Menggunakan High() untuk batas akhir perulangan Array
  for i := 0 to High(FEconomy.History) do
  begin
    Rep := FEconomy.History[i];
    RowIdx := i + 1; // Baris 0 dipakai Header

    if Rep.GrossIncome > 0 then
      MarginRatio := (Rep.NetProfit / Rep.GrossIncome) * 100
    else
      MarginRatio := 0;

    GridLedger.Cells[0, RowIdx] := IntToStr(Rep.DayNumber);
    GridLedger.Cells[1, RowIdx] := 'Rp ' + IntToStr(Rep.GrossIncome);
    GridLedger.Cells[2, RowIdx] := 'Rp ' + IntToStr(Rep.OperatingCost);
    GridLedger.Cells[3, RowIdx] := 'Rp ' + IntToStr(Rep.SpoilageLoss);
    GridLedger.Cells[4, RowIdx] := 'Rp ' + IntToStr(Rep.TaxDeduction);
    GridLedger.Cells[5, RowIdx] := 'Rp ' + IntToStr(Rep.NetProfit);
    GridLedger.Cells[6, RowIdx] := Format('%.2f %%', [MarginRatio]);
  end;
end;

end.
