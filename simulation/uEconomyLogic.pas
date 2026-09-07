unit uEconomyLogic;

{$mode objfpc}{$H+}
{$OPTIMIZATION LEVEL3}

interface

uses
  SysUtils, Math, uConstants, uGameTypes, uInventorySys;

type
  TWeatherType = (wtClear, wtRain, wtHot);

  TDailyReport = record
    DayNumber: Integer;
    GrossIncome: Int64;
    SpoilageLoss: Int64;
    OperatingCost: Int64;
    TaxDeduction: Int64;
    NetProfit: Int64;
  end;

  TDailyReportArray = array of TDailyReport;

  TEconomyManager = class
  private
    FCash: Int64;
    FDayCount: Integer;
    FCurrentWeather: TWeatherType;
    FTodayReport: TDailyReport;
    FInventory: TInventoryManager;

    FHistory: TDailyReportArray;

    procedure GenerateDailyWeather;
  public
    constructor Create(AInventoryManager: TInventoryManager);
    destructor Destroy; override;

    procedure StartNewDay;

    // --> PERBAIKAN: Menambahkan parameter Gaji Karyawan (AStaffSalary)
    procedure EndOfDay(const ASpoilageCost: Int64; const AStaffSalary: Int64);

    procedure AddCash(const Amount: Int64); inline;
    function DeductCash(const Amount: Int64): Boolean; inline;

    function CalculateNetWorth: Int64;
    function GetDemandModifier(ACategory: TProductCategory): Single;

    property Cash: Int64 read FCash;
    property DayCount: Integer read FDayCount write FDayCount;
    property Weather: TWeatherType read FCurrentWeather;
    property Report: TDailyReport read FTodayReport;
    property History: TDailyReportArray read FHistory write FHistory;
  end;

implementation

constructor TEconomyManager.Create(AInventoryManager: TInventoryManager);
begin
  FInventory := AInventoryManager;
  FCash := STARTING_CAPITAL;
  FDayCount := 0;
  FCurrentWeather := wtClear;

  FillChar(FTodayReport, SizeOf(TDailyReport), 0);

  SetLength(FHistory, 0);
end;

destructor TEconomyManager.Destroy;
begin
  SetLength(FHistory, 0);
  inherited Destroy;
end;

procedure TEconomyManager.GenerateDailyWeather;
var
  Roll: Integer;
begin
  Roll := Random(100);
  if Roll < 60 then FCurrentWeather := wtClear
  else if Roll < 80 then FCurrentWeather := wtRain
  else FCurrentWeather := wtHot;
end;

procedure TEconomyManager.StartNewDay;
begin
  Inc(FDayCount);
  GenerateDailyWeather();

  FillChar(FTodayReport, SizeOf(TDailyReport), 0);
  FTodayReport.DayNumber := FDayCount;
  // Beban operasional dasar harian (listrik, air, dsb)
  FTodayReport.OperatingCost := 50000 + (FDayCount * 2500);
end;

// --> PERBAIKAN: Implementasi Pemotongan Gaji Karyawan di Penghujung Hari
procedure TEconomyManager.EndOfDay(const ASpoilageCost: Int64; const AStaffSalary: Int64);
begin
  FTodayReport.SpoilageLoss := ASpoilageCost;

  // 1. Tambahkan Gaji Karyawan ke Beban Operasional
  FTodayReport.OperatingCost := FTodayReport.OperatingCost + AStaffSalary;

  // 2. Pajak 0.5% tetap dihitung dari Gross Income (Omzet Bruto)
  FTodayReport.TaxDeduction := Trunc(FTodayReport.GrossIncome * 0.005);

  // 3. Potong uang kas nyata di dalam dompet (Cash)
  FCash := FCash - FTodayReport.OperatingCost - FTodayReport.TaxDeduction;

  // 4. Hitung Laba Bersih (Net Profit)
  FTodayReport.NetProfit := FTodayReport.GrossIncome - FTodayReport.OperatingCost -
                            FTodayReport.SpoilageLoss - FTodayReport.TaxDeduction;

  // 5. Simpan ke memori Array Buku Besar
  SetLength(FHistory, Length(FHistory) + 1);
  FHistory[High(FHistory)] := FTodayReport;
end;

procedure TEconomyManager.AddCash(const Amount: Int64); inline;
begin
  if Amount > 0 then
  begin
    FCash := FCash + Amount;
    FTodayReport.GrossIncome := FTodayReport.GrossIncome + Amount;
  end;
end;

function TEconomyManager.DeductCash(const Amount: Int64): Boolean; inline;
begin
  if FCash >= Amount then
  begin
    FCash := FCash - Amount;
    Result := True;
  end
  else Result := False;
end;

function TEconomyManager.CalculateNetWorth: Int64;
var
  i: Integer;
  Def: TProductDef;
  AssetValue: Int64;
begin
  AssetValue := 0;
  if Assigned(FInventory) then
  begin
    for i := 0 to FInventory.Stocks.Count - 1 do
    begin
      if FInventory.GetProductDef(FInventory.Stocks[i].ProductID, Def) then
        AssetValue := AssetValue + (Int64(Def.BaseCost) * Int64(FInventory.Stocks[i].Qty));
    end;
  end;
  Result := FCash + AssetValue;
end;

function TEconomyManager.GetDemandModifier(ACategory: TProductCategory): Single;
begin
  Result := 1.0;
  case FCurrentWeather of
    wtRain:
      begin
        if ACategory = pcStaple then Result := 1.2
        else if ACategory = pcSnack then Result := 1.5
        else if ACategory = pcTertiary then Result := 0.8;
      end;
    wtHot:
      begin
        if ACategory = pcSnack then Result := 1.3
        else if ACategory = pcStaple then Result := 0.9;
      end;
    wtClear: Result := 1.0;
  end;
end;

end.
