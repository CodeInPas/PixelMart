unit uMathHelper;

{$mode objfpc}{$H+}

// Mengaktifkan fitur inlining dan instruksi optimasi maksimal
{$INLINE ON}
{$OPTIMIZATION LEVEL3}

interface

uses
  SysUtils, Math, uGameTypes;

// =========================================================================
// 1. DISTANCE & PATHFINDING HEURISTICS
// =========================================================================

{ Menghitung jarak langkah blok (Grid). Sangat cepat, digunakan untuk A* atau BFS. }
function ManhattanDistance(const P1, P2: TGridPos): Integer; inline;

{ Menghitung jarak pixel. Menghindari pemakaian Sqrt (Akar) untuk perbandingan
  jarak demi menghemat clock-cycles CPU (O(1) fast execution). }
function EuclideanDistanceSqr(const P1, P2: TFloatPos): Single; inline;

// =========================================================================
// 2. MOVEMENT & INTERPOLATION (RENDERING)
// =========================================================================

{ Linear Interpolation: Menggerakkan sprite secara halus antar grid. }
function Lerp(const StartVal, EndVal, T: Single): Single; inline;

{ Memastikan pergerakan tidak kebablasan melewati target. }
function MoveTowards(const Current, Target, MaxDelta: Single): Single; inline;

// =========================================================================
// 3. CLAMPING & BOUNDING
// =========================================================================

function ClampInt(const Value, MinVal, MaxVal: Integer): Integer; inline;
function ClampFloat(const Value, MinVal, MaxVal: Single): Single; inline;

// =========================================================================
// 4. ECONOMY & PROBABILITY LOGIC
// =========================================================================

{ Menghasilkan True/False berdasarkan persentase desimal (0.00 hingga 1.00) }
function RollChance(const Probability: Single): Boolean; inline;

{ Rumus utama GDD: Kalkulasi keputusan pembeli mengambil barang di rak }
function CalcPurchaseProbability(const SellPrice, BasePrice: Integer; const PriceTolerance, NeedMod: Single): Single; inline;


implementation

// =========================================================================

function ManhattanDistance(const P1, P2: TGridPos): Integer; inline;
begin
  Result := Abs(P1.X - P2.X) + Abs(P1.Y - P2.Y);
end;

function EuclideanDistanceSqr(const P1, P2: TFloatPos): Single; inline;
begin
  Result := Sqr(P1.X - P2.X) + Sqr(P1.Y - P2.Y);
end;

function Lerp(const StartVal, EndVal, T: Single): Single; inline;
begin
  // Formula Lerp presisi: Start + (End - Start) * T
  Result := StartVal + ((EndVal - StartVal) * T);
end;

function MoveTowards(const Current, Target, MaxDelta: Single): Single; inline;
begin
  if Abs(Target - Current) <= MaxDelta then
    Result := Target
  else if Target > Current then
    Result := Current + MaxDelta
  else
    Result := Current - MaxDelta;
end;

function ClampInt(const Value, MinVal, MaxVal: Integer): Integer; inline;
begin
  if Value < MinVal then Result := MinVal
  else if Value > MaxVal then Result := MaxVal
  else Result := Value;
end;

function ClampFloat(const Value, MinVal, MaxVal: Single): Single; inline;
begin
  if Value < MinVal then Result := MinVal
  else if Value > MaxVal then Result := MaxVal
  else Result := Value;
end;

function RollChance(const Probability: Single): Boolean; inline;
begin
  // Random mengembalikan nilai float 0.0 <= x < 1.0
  Result := Random < Probability;
end;

function CalcPurchaseProbability(const SellPrice, BasePrice: Integer; const PriceTolerance, NeedMod: Single): Single; inline;
var
  Diff: Single;
  Penalty: Single;
begin
  // Mencegah Division by Zero jika BaseCost tidak di set dengan benar
  if (BasePrice <= 0) or (PriceTolerance <= 0) then Exit(0.0);

  Diff := SellPrice - BasePrice;
  Penalty := Diff / (BasePrice * PriceTolerance);

  // Formula: Max(0, 1 - Penalty) * Modifikator Kebutuhan (Cuaca/Event)
  Result := (1.0 - Penalty) * NeedMod;

  if Result < 0.0 then Result := 0.0
  else if Result > 1.0 then Result := 1.0;
end;

end.
