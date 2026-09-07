unit uSaveLoad;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, uConstants, uGameTypes, uWorldGrid,
  uInventorySys, uEconomyLogic;

procedure SaveGameData(const AFileName: String; AGrid: TWorldGrid; AInv: TInventoryManager; AEco: TEconomyManager);
function LoadGameData(const AFileName: String; AGrid: TWorldGrid; AInv: TInventoryManager; AEco: TEconomyManager): Boolean;

implementation

procedure SaveGameData(const AFileName: String; AGrid: TWorldGrid; AInv: TInventoryManager; AEco: TEconomyManager);
var
  Ini: TIniFile;
  x, y, RackIdx, i: Integer;
  Cell: PGridCell;
  Item: TStockItem;
  Rep: TDailyReport;
begin
  Ini := TIniFile.Create(AFileName);
  try
    // 1. Simpan Core Ekonomi
    Ini.WriteInt64('Economy', 'Cash', AEco.Cash);
    Ini.WriteInteger('Economy', 'DayCount', AEco.DayCount);

    // --> SIMPAN HISTORI BUKU BESAR & PAJAK
    Ini.WriteInteger('Economy', 'HistoryCount', Length(AEco.History));
    for i := 0 to High(AEco.History) do
    begin
      Rep := AEco.History[i];
      Ini.WriteString('Economy', 'Hist_' + IntToStr(i),
        Format('%d,%d,%d,%d,%d,%d', [Rep.DayNumber, Rep.GrossIncome, Rep.SpoilageLoss, Rep.OperatingCost, Rep.TaxDeduction, Rep.NetProfit]));
    end;

    // 2. Simpan Grid (Hanya Rak)
    RackIdx := 0;
    for x := 0 to GRID_COLS - 1 do
    begin
      for y := 0 to GRID_ROWS - 1 do
      begin
        Cell := AGrid.GetCellPtr(x, y);
        if Cell^.TileType = ttRack then
        begin
          Ini.WriteString('Grid', 'Rack_' + IntToStr(RackIdx), Format('%d,%d', [x, y]));
          Inc(RackIdx);
        end;
      end;
    end;
    Ini.WriteInteger('Grid', 'RackCount', RackIdx);

    // 3. Simpan Inventori
    Ini.WriteInteger('Inventory', 'StockCount', AInv.Stocks.Count);
    for i := 0 to AInv.Stocks.Count - 1 do
    begin
      Item := AInv.Stocks[i];
      Ini.WriteString('Inventory', 'Stock_' + IntToStr(i),
        Format('%s,%d,%d,%d', [Item.ProductID, Item.Qty, Item.SellPrice, Item.DaysToExpiry]));
    end;
  finally
    Ini.Free;
  end;
end;

function LoadGameData(const AFileName: String; AGrid: TWorldGrid; AInv: TInventoryManager; AEco: TEconomyManager): Boolean;
var
  Ini: TIniFile;
  i, RackCount, StockCount, HistCount: Integer;
  DataStr: String;
  StrList: TStringList;
  NewItem: TStockItem;
  TempHist: TDailyReportArray;
begin
  if not FileExists(AFileName) then Exit(False);

  Ini := TIniFile.Create(AFileName);
  StrList := TStringList.Create;
  try
    // 1. Muat Core Ekonomi
    AEco.AddCash(Ini.ReadInt64('Economy', 'Cash', 500000) - AEco.Cash);
    AEco.DayCount := Ini.ReadInteger('Economy', 'DayCount', 1);

    // --> MUAT HISTORI BUKU BESAR & PAJAK
    HistCount := Ini.ReadInteger('Economy', 'HistoryCount', 0);
    SetLength(TempHist, HistCount);
    for i := 0 to HistCount - 1 do
    begin
      DataStr := Ini.ReadString('Economy', 'Hist_' + IntToStr(i), '');
      StrList.CommaText := DataStr;
      if StrList.Count = 6 then
      begin
        TempHist[i].DayNumber := StrToInt(StrList[0]);
        TempHist[i].GrossIncome := StrToInt64(StrList[1]);
        TempHist[i].SpoilageLoss := StrToInt64(StrList[2]);
        TempHist[i].OperatingCost := StrToInt64(StrList[3]);
        TempHist[i].TaxDeduction := StrToInt64(StrList[4]);
        TempHist[i].NetProfit := StrToInt64(StrList[5]);
      end;
    end;
    AEco.History := TempHist;

    // 2. Muat Grid
    RackCount := Ini.ReadInteger('Grid', 'RackCount', 0);
    for i := 0 to RackCount - 1 do
    begin
      DataStr := Ini.ReadString('Grid', 'Rack_' + IntToStr(i), '0,0');
      StrList.CommaText := DataStr;
      if StrList.Count = 2 then
        AGrid.SetTile(StrToInt(StrList[0]), StrToInt(StrList[1]), ttRack);
    end;

    // 3. Muat Inventori
    AInv.Stocks.Clear;
    StockCount := Ini.ReadInteger('Inventory', 'StockCount', 0);
    for i := 0 to StockCount - 1 do
    begin
      DataStr := Ini.ReadString('Inventory', 'Stock_' + IntToStr(i), '');
      StrList.CommaText := DataStr;
      if StrList.Count = 4 then
      begin
        NewItem.ProductID := StrList[0];
        NewItem.Qty := StrToInt(StrList[1]);
        NewItem.SellPrice := StrToInt(StrList[2]);
        NewItem.DaysToExpiry := StrToInt(StrList[3]);
        AInv.Stocks.Add(NewItem);
      end;
    end;

    Result := True;
  finally
    StrList.Free;
    Ini.Free;
  end;
end;

end.
