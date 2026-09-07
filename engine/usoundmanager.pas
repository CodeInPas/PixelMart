unit uSoundManager;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MMSystem; // Pustaka sakti pembaca audio bawaan Windows

type
  TSoundManager = class
  private
    FAssetDir: String;
  public
    constructor Create;
    procedure PlaySFX(const AFileName: String);
  end;

var
  SoundFX: TSoundManager;

implementation

constructor TSoundManager.Create;
begin
  // Arahkan folder audio ke assets/sfx/
  FAssetDir := ExpandFileName(ExtractFilePath(ParamStr(0)) + 'assets\sfx\');

  if not DirectoryExists(FAssetDir) then
    ForceDirectories(FAssetDir);
end;

procedure TSoundManager.PlaySFX(const AFileName: String);
var
  FullPath: String;
begin
  FullPath := FAssetDir + AFileName;

  if FileExists(FullPath) then
  begin
    // SND_ASYNC = Mainkan di background agar game tidak freeze
    // SND_FILENAME = Mode baca dari lokasi file
    PlaySound(PChar(FullPath), 0, SND_ASYNC or SND_FILENAME);
  end;
end;

initialization
  SoundFX := TSoundManager.Create;
finalization
  if Assigned(SoundFX) then FreeAndNil(SoundFX);
end.
