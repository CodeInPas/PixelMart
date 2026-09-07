unit fSummary;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  uEconomyLogic;

type
  { TSummaryForm }
  TSummaryForm = class(TForm)
    btnNextDay: TButton;
    lblTitle: TLabel;
    lblCash: TLabel;
    pnlBackground: TPanel;
    procedure btnNextDayClick(Sender: TObject);
  private
    FEconomy: TEconomyManager;
  public
    constructor CreateWithEngine(AOwner: TComponent; AEco: TEconomyManager);
    procedure RefreshData;
  end;

var
  SummaryForm: TSummaryForm;

implementation

{$R *.lfm}

constructor TSummaryForm.CreateWithEngine(AOwner: TComponent; AEco: TEconomyManager);
begin
  inherited Create(AOwner);
  FEconomy := AEco;
  RefreshData;
end;

procedure TSummaryForm.RefreshData;
var
  Rep: TDailyReport;
  MarginRatio: Single;
begin
  Rep := FEconomy.Report;

  // Kalkulasi Analisis Vertikal (Margin Laba Bersih)
  if Rep.GrossIncome > 0 then
    MarginRatio := (Rep.NetProfit / Rep.GrossIncome) * 100
  else
    MarginRatio := 0;

  lblTitle.Caption := 'Rekapitulasi Keuangan (Hari Ke-' + IntToStr(Rep.DayNumber) + ')';

  // Format laporan komersial multi-baris
  lblCash.Caption :=
    'Peredaran Bruto (Omzet): Rp ' + IntToStr(Rep.GrossIncome) + sLineBreak +
    'Beban Operasional: Rp ' + IntToStr(Rep.OperatingCost) + sLineBreak +
    'Kerugian Kedaluwarsa: Rp ' + IntToStr(Rep.SpoilageLoss) + sLineBreak +
    'PPh Final UMKM (0.5%): Rp ' + IntToStr(Rep.TaxDeduction) + sLineBreak +
    '---------------------------------------' + sLineBreak +
    'Laba Bersih: Rp ' + IntToStr(Rep.NetProfit) + sLineBreak +
    Format('Net Profit Margin: %.2f%%', [MarginRatio]);
end;

procedure TSummaryForm.btnNextDayClick(Sender: TObject);
begin
  Self.ModalResult := mrOk; // Menutup jendela dan memberi sinyal OK
end;

end.
