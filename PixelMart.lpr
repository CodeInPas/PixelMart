program PixelMart;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // Inisialisasi LCL widgetset
  Forms, fMain, uMathHelper, uPathfinding, uCustomerAI, uEconomyLogic,
  uInventorySys, uWorldGrid, uConstants, uGameTypes, uDoubleBuffer, uGameLoop,
  uRenderer, uSaveLoad, fPricing, fStockMonitor;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

