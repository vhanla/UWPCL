unit UWP.SystemSettings;

interface

uses
  UWP.Classes, Registry, Windows, Graphics;

function GetAccentColor: TColor;
function IsColorOnBorderEnabled: Boolean;
function IsColorOnCanvasEnabeld: Boolean;
function IsDarkUsedInApp:Boolean;
function IsDarkUsedInSystem: Boolean;
function IsTransparencyEnabled: Boolean;

implementation

function GetAccentColor: TColor;
var
  reg: TRegistry;
  ARGB: Cardinal;
begin
  Result := $D77800;

  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;

    if reg.OpenKeyReadOnly('Software\Microsoft\Windows\DWM\')
      and reg.ValueExists('AccentColor') then
    begin
      ARGB := reg.ReadInteger('AccentColor');
      Result := ARGB mod $FF000000;
    end;
  finally
    reg.Free;
  end;
end;

function IsColorOnBorderEnabled: Boolean;
var
  reg: TRegistry;
begin
  Result := False;

  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;

    if reg.OpenKeyReadOnly('Software\Microsoft\Windows\DWM\')
      and reg.ValueExists('ColorPrevalence') then
    begin
      Result := reg.ReadInteger('ColorPrevalence') <> 0;
    end;
  finally
    reg.Free;
  end;
end;

function IsColorOnCanvasEnabeld: Boolean;
var
  reg: TRegistry;
begin
  Result := False;

  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;

    if reg.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion\Themes\Personalize\')
      and reg.ValueExists('ColorPrevalence') then
    begin
      Result := reg.ReadInteger('ColorPrevalence') <> 0;
    end;
  finally
    reg.Free;
  end;
end;

function IsDarkUsedInApp:Boolean;
var
  reg: TRegistry;
begin
  Result := False;

  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;

    if reg.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion\Themes\Personalize\')
      and reg.ValueExists('AppsUseLightTheme') then
    begin
      Result := reg.ReadInteger('AppsUseLightTheme') <> 1;
    end;
  finally
    reg.Free;
  end;
end;

function IsDarkUsedInSystem: Boolean;
var
  reg: TRegistry;
begin
  Result := False;

  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;

    if reg.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion\Themes\Personalize')
      and reg.ValueExists('SystemUsesLightTheme') then
    begin
      Result := reg.ReadInteger('SystemUsesLightTheme') <> 1;
    end;
  finally
    reg.Free;
  end;
end;

function IsTransparencyEnabled: Boolean;
var
  reg: TRegistry;
begin
  Result := False;

  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;

    if reg.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion\Themes\Personalize')
      and reg.ValueExists('EnableTransparency') then
    begin
      Result := reg.ReadInteger('EnableTransparency') <> 1;
    end;
  finally
    reg.Free;
  end;
end;

end.
