unit UWP.ColorManager;

interface

uses
  Classes, Graphics,
  UWP.Classes, UWP.SystemSettings;

type
  TUWPColorizationType = (ctAuto, ctLight, ctDark);
  TUWPAccentColorType = TColor;

  IUWPControl = interface
    ['{E4449DAB-BA83-45E3-8442-598950550008}']
    function IsContainer: Boolean;
    procedure UpdateColorization(const IncludeChildre: Boolean);
  end;

  TUWPColorizationManager = class(TPersistent)
  private
    FColorization: TUWPColorization;
    FAccentColor: TColor;
    FColoredBorder: Boolean;

    FColorizationType: TUWPColorizationType;
    FAccentColorType: TUWPAccentColorType;

    FOnChange: TNotifyEvent;

    procedure SetColorizationType(const AValue: TUWPColorizationType);
    procedure SetAccentColorType(const AValue: TUWPAccentColorType);
  protected
    procedure Changed;
  public
    constructor Create;
    procedure UpdateColorization;

    procedure Assign(ASource: TPersistent); override;

  published
    property Colorization: TUWPColorization read FColorization stored False;
    property AccentColor: TColor read FAccentColor stored False;
    property ColoredBorder: Boolean read FColoredBorder stored False;

    property ColorizationType: TUWPColorizationType read FColorizationType write SetColorizationType default ctAuto;
    property AccentColorType: TUWPAccentColorType read FAccentColorType write SetAccentColorType default 0;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

{ TUWPColorizationManager }

procedure TUWPColorizationManager.Assign(ASource: TPersistent);
begin
  if ASource is TUWPColorizationManager then
  begin
    FColorizationType := TUWPColorizationManager(ASource).ColorizationType;
    FAccentColorType := TUWPColorizationManager(ASource).AccentColorType;

    FColorization := TUWPColorizationManager(ASource).Colorization;
    FAccentColor := TUWPColorizationManager(ASource).AccentColor;
    FColoredBorder := TUWPColorizationManager(ASource).ColoredBorder;

    Changed;
  end
  else
    inherited;
end;

procedure TUWPColorizationManager.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

constructor TUWPColorizationManager.Create;
begin
  inherited;

  FColorization := ucLight;
  FAccentColor := $D77800;
  FColoredBorder := False;

  FColorizationType := ctAuto;
  FAccentColorType := 0;
end;

procedure TUWPColorizationManager.SetAccentColorType(
  const AValue: TUWPAccentColorType);
begin
  if AValue <> FAccentColorType then
  begin
    FAccentColorType := AValue;
    if AValue = 0 then
      FAccentColor := GetAccentColor
    else
      FAccentColor := FAccentColorType;
    Changed;
  end;
end;

procedure TUWPColorizationManager.SetColorizationType(
  const AValue: TUWPColorizationType);
begin
  if AValue <> FColorizationType then
  begin
    FColorizationType := AValue;
    case AValue of
      ctAuto:
        if IsDarkUsedInApp then
          FColorization := ucDark
        else
          FColorization := ucLight;

      ctLight:
        FColorization := ucLight;
      ctDark:
        FColorization := ucDark;
    end;
    UpdateColorization;
  end;
end;

procedure TUWPColorizationManager.UpdateColorization;
begin
  if FColorizationType = ctAuto then
    if IsDarkUsedInApp then
      FColorization := ucDark
    else
      FColorization := ucLight;

  if FAccentColorType = 0 then
    FAccentColor := GetAccentColor;

  FColoredBorder := IsColorOnBorderEnabled;

  Changed;
end;

end.
