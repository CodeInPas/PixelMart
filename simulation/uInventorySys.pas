unit uInventorySys;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fgl, uGameTypes, uConstants, Math;

type

  { TInventoryManager
    Mengatur master data produk dan logika mutasi stok gudang/etalase secara FIFO. }
  TInventoryManager = class
  private
    FStocks: TStockList;
    FMasterProducts: specialize TFPGMap<String, TProductDef>;
    function FindBatchIndex(const AProductID: ShortString; ADaysToExpiry, ASellPrice: Integer): Integer;
  public
    CatalogIDs: TStringList; // --> Untuk menyimpan daftar semua ID barang
    constructor Create;
    destructor Destroy; override;

    { Inisialisasi Database Produk Dasar }
    procedure LoadProductsFromCSV;

    { Transaksi & Mutasi }
    procedure AddStock(const AProductID: ShortString; AQty, ASellPrice: Integer);
    function TakeStock(const AProductID: ShortString; AQty: Integer): Boolean;

    // --> FUNGSI BARU: Jembatan untuk AI Pelanggan mengambil 1 barang
    function TakeItem(const AProductID: String): Boolean;

    procedure ChangeSellPrice(const AProductID: ShortString; ANewPrice: Integer);

    { Pengecekan }
    function GetTotalStock(const AProductID: ShortString): Integer;
    function GetProductDef(const AID: String; out OutDef: TProductDef): Boolean;

    { Fase Malam: Eksekusi penyusutan dan kedaluwarsa }
    procedure ProcessEndOfDay(out TotalLoss: Integer);

    property Stocks: TStockList read FStocks;
    property MasterProducts: TProductDefMap read FMasterProducts;
    procedure RegisterProduct(ADef: TProductDef);
  end;

implementation

constructor TInventoryManager.Create;
begin
  FMasterProducts := TProductDefMap.Create;
  FMasterProducts.Sorted := True; // Mengaktifkan O(log N) Binary Search lookup

  FStocks := TStockList.Create;
  CatalogIDs := TStringList.Create; // Inisialisasi list
end;

destructor TInventoryManager.Destroy;
begin
  FMasterProducts.Free;
  FStocks.Free;
  CatalogIDs.Free; // Bersihkan memori
  inherited Destroy;
end;

procedure TInventoryManager.LoadProductsFromCSV;
var
  CSVFile, RowData: TStringList;
  FilePath, Line: String;
  i: Integer;
  Def: TProductDef;
begin
  // 1. Cari file CSV di folder assets
  FilePath := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'assets\products.csv');

  if not FileExists(FilePath) then
  begin
    // Fallback jika file hilang
    Def.ID := 'ERR-01';
    Def.Name := 'Data CSV Hilang!';
    Def.Category := pcStaple;
    Def.BaseCost := 0;
    Def.MaxExpiry := 1;
    RegisterProduct(Def);
    CatalogIDs.Add(Def.ID);
    Exit;
  end;

  CSVFile := TStringList.Create;
  RowData := TStringList.Create;
  try
    CSVFile.LoadFromFile(FilePath);
    RowData.StrictDelimiter := True; // Agar spasi tidak dianggap pemisah
    RowData.Delimiter := ',';        // Pemisah kolom CSV

    CatalogIDs.Clear;

    // 2. Looping membaca baris dari CSV (Mulai dari 1 untuk melompati Header)
    for i := 1 to CSVFile.Count - 1 do
    begin
      Line := Trim(CSVFile[i]);
      if Line = '' then Continue;

      RowData.DelimitedText := Line;

      // Pastikan ada 5 kolom sesuai format CSV kita
      if RowData.Count >= 5 then
      begin
        Def.ID := Trim(RowData[0]);
        Def.Name := Trim(RowData[1]);

        // Terjemahkan string kategori ke tipe Enum
        if UpperCase(Trim(RowData[2])) = 'SEMBAKO' then Def.Category := pcStaple
        else if UpperCase(Trim(RowData[2])) = 'JAJANAN' then Def.Category := pcSnack
        else Def.Category := pcTertiary;

        Def.BaseCost := StrToIntDef(Trim(RowData[3]), 0);
        Def.MaxExpiry := StrToIntDef(Trim(RowData[4]), 1);

        // Masukkan ke mesin database game
        RegisterProduct(Def);
        CatalogIDs.Add(Def.ID); // Catat ID-nya agar mudah dipanggil UI
      end;
    end;
  finally
    CSVFile.Free;
    RowData.Free;
  end;
end;

function TInventoryManager.FindBatchIndex(const AProductID: ShortString; ADaysToExpiry, ASellPrice: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to FStocks.Count - 1 do
  begin
    if (FStocks[i].ProductID = AProductID) and
       (FStocks[i].DaysToExpiry = ADaysToExpiry) and
       (FStocks[i].SellPrice = ASellPrice) then
    begin
      Exit(i);
    end;
  end;
end;

procedure TInventoryManager.AddStock(const AProductID: ShortString; AQty, ASellPrice: Integer);
var
  Def: TProductDef;
  Idx: Integer;
  NewItem, ItemToUpdate: TStockItem;
begin
  if AQty <= 0 then Exit;
  if not GetProductDef(AProductID, Def) then Exit; // Produk tidak terdaftar

  Idx := FindBatchIndex(AProductID, Def.MaxExpiry, ASellPrice);

  if Idx <> -1 then
  begin
    // Tumpuk ke batch yang sudah ada jika harga dan exp sama
    ItemToUpdate := FStocks[Idx];
    ItemToUpdate.Qty := ItemToUpdate.Qty + AQty;
    FStocks[Idx] := ItemToUpdate;
  end
  else
  begin
    // Buat batch stok baru
    NewItem.ProductID := AProductID;
    NewItem.Qty := AQty;
    NewItem.SellPrice := ASellPrice;
    NewItem.DaysToExpiry := Def.MaxExpiry;
    FStocks.Add(NewItem);
  end;
end;

// --> IMPLEMENTASI FUNGSI BARU: Jembatan untuk AI
function TInventoryManager.TakeItem(const AProductID: String): Boolean;
begin
  // Kita manfaatkan langsung logika FIFO tingkat tinggi yang sudah ada di TakeStock!
  Result := TakeStock(ShortString(AProductID), 1);
end;

function TInventoryManager.TakeStock(const AProductID: ShortString; AQty: Integer): Boolean;
var
  i, BestIdx: Integer;
  MinExp, QtyNeeded, TakeAmt: Integer;
  Item: TStockItem;
begin
  Result := False;
  if GetTotalStock(AProductID) < AQty then Exit; // Stok tidak cukup

  QtyNeeded := AQty;

  // Logika FIFO (Ambil umur terpendek berulang kali sampai kebutuhan terpenuhi)
  while QtyNeeded > 0 do
  begin
    BestIdx := -1;
    MinExp := MaxInt;

    // Cari batch barang dengan umur tersingkat (DaysToExpiry paling kecil)
    for i := 0 to FStocks.Count - 1 do
    begin
      if (FStocks[i].ProductID = AProductID) and (FStocks[i].Qty > 0) then
      begin
        // Jika barang awet (0), taruh di prioritas paling belakang dari barang yang mau kedaluwarsa
        if (FStocks[i].DaysToExpiry > 0) and (FStocks[i].DaysToExpiry < MinExp) then
        begin
          MinExp := FStocks[i].DaysToExpiry;
          BestIdx := i;
        end
        else if (FStocks[i].DaysToExpiry = 0) and (BestIdx = -1) then
        begin
          BestIdx := i;
        end;
      end;
    end;

    if BestIdx = -1 then Break; // Failsafe (seharusnya tidak terjadi karena cek TotalStock di atas)

    Item := FStocks[BestIdx];

    if Item.Qty <= QtyNeeded then TakeAmt := Item.Qty
    else TakeAmt := QtyNeeded;

    Item.Qty := Item.Qty - TakeAmt;
    QtyNeeded := QtyNeeded - TakeAmt;

    // Update list atau hapus batch jika habis
    if Item.Qty <= 0 then
      FStocks.Delete(BestIdx)
    else
      FStocks[BestIdx] := Item;
  end;

  Result := True;
end;

procedure TInventoryManager.ChangeSellPrice(const AProductID: ShortString; ANewPrice: Integer);
var
  i: Integer;
  Item: TStockItem;
begin
  for i := 0 to FStocks.Count - 1 do
  begin
    if FStocks[i].ProductID = AProductID then
    begin
      Item := FStocks[i];
      Item.SellPrice := ANewPrice;
      FStocks[i] := Item; // Write-back to list
    end;
  end;
end;

function TInventoryManager.GetTotalStock(const AProductID: ShortString): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to FStocks.Count - 1 do
  begin
    if FStocks[i].ProductID = AProductID then
      Result := Result + FStocks[i].Qty;
  end;
end;

function TInventoryManager.GetProductDef(const AID: String; out OutDef: TProductDef): Boolean;
var
  Idx: Integer;
begin
  // Langsung cari laci berdasarkan ID (Tanpa perlu di-loop satu per satu!)
  Idx := FMasterProducts.IndexOf(AID);

  if Idx >= 0 then
  begin
    OutDef := FMasterProducts.Data[Idx];
    Result := True;
  end
  else
    Result := False;
end;

procedure TInventoryManager.ProcessEndOfDay(out TotalLoss: Integer);
var
  i: Integer;
  Def: TProductDef;
  TempItem: TStockItem;
begin
  TotalLoss := 0;

  // ITERASI TERBALIK: Dari indeks paling akhir ke 0
  // Wajib dilakukan agar urutan List tidak bergeser error saat ada barang yang dihapus
  for i := Stocks.Count - 1 downto 0 do
  begin
    // Ambil salinan record barang ke variabel sementara
    TempItem := Stocks[i];

    // Kurangi sisa umur kedaluwarsa 1 hari
    Dec(TempItem.DaysToExpiry);

    if TempItem.DaysToExpiry <= 0 then
      begin
        // BARANG BASI! Hitung kerugian berdasarkan harga modal awal (Base Cost)
        if GetProductDef(TempItem.ProductID, Def) then
        begin
          TotalLoss := TotalLoss + (Def.BaseCost * TempItem.Qty);
        end;

        // Buang barang secara permanen dari daftar stok
        Stocks.Delete(i);
      end
    else
      begin
        // Jika belum basi, simpan kembali umur barunya ke dalam memori List
        Stocks[i] := TempItem;
      end;
  end;
end;

procedure TInventoryManager.RegisterProduct(ADef: TProductDef);
begin
  // TFPGMap menggunakan format: .Add(Kunci, Data)
  FMasterProducts.Add(ADef.ID, ADef);
end;

end.
