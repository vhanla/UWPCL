unit UWP.Text;

interface

uses
  Classes, Windows, Controls, StdCtrls, Graphics,
  UWP.Classes, UWP.ColorManager, UWP.Colors;

type
  TUWPLabelKind = (lkCustom, lkNormal, lkDescription, lkEntry, lkHeading, lkTitle);

  TUWPLabel = class(TLabel, IUWPControl)
  private
    var LastFont: TFont;

    FEnabled: Boolean;
    FLabelKind: TUWPLabelKind;
    FUseAccentColor: Boolean;

    // Setters
    procedure SetEnabled(const AValue: Boolean); reintroduce;
    procedure SetLabelKind(const AValue: TUWPLabelKind);
    procedure SetUseAccentColor(const AValue: Boolean);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Interface
    function IsContainer: Boolean;
    procedure UpdateColorization(const IncludeChildren: Boolean);

  published
    // reintroducte Enabled to fix double shadow on disabled text in dark color
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property LabelKind: TUWPLabelKind read FLabelKind write SetLabelKind default lkCustom;
    property UseAccentColor: Boolean read FUseAccentColor write SetUseAccentColor default False;
  end;
implementation

{ TUWPLabel }

constructor TUWPLabel.Create(AOwner: TComponent);
begin
  inherited;
  FEnabled := True;
  FLabelKind := lkCustom;
  FUseAccentColor := False;

  LastFont := TFont.Create;
end;

destructor TUWPLabel.Destroy;
begin
  LastFont.Free;
  inherited;
end;

function TUWPLabel.IsContainer: Boolean;
begin
  Result := False;
end;

procedure TUWPLabel.SetEnabled(const AValue: Boolean);
begin
  if AValue <> FEnabled then
  begin
    FEnabled := AValue;
    UpdateColorization(True);
  end;
end;

procedure TUWPLabel.SetLabelKind(const AValue: TUWPLabelKind);
begin
  if AValue <> FLabelKind then
  begin
    // Save current font
    if FLabelKind = lkCustom then
      LastFont.Assign(Font);

    FLabelKind := AValue;

    if AValue = lkCustom then
      // restore the saved font
      Font.Assign(LastFont)
    else
      begin
        if AValue = lkEntry then
          Font.Name := 'Segoe UI Semibold'
        else
          Font.Name := 'Segoe UI';

        // Font size
        case AValue of
          lkNormal:
            Font.Size := 10;
          lkDescription:
            Font.Size := 9;
          lkEntry:
            Font.Size := 10;
          lkHeading:
            Font.Size := 15;
          lkTitle:
            Font.Size := 21;
        end;
      end;

      UpdateColorization(True);
  end;
end;

procedure TUWPLabel.SetUseAccentColor(const AValue: Boolean);
begin
  if AValue <> FUseAccentColor then
  begin
    FUseAccentColor := AValue;
    UpdateColorization(True);
  end;
end;

procedure TUWPLabel.UpdateColorization(const IncludeChildren: Boolean);
var
  LCM: TUWPColorizationManager;
begin
  LCM := SelectColorizationManager(Self);

  // Disabled or description
  if (not FEnabled) or (LabelKind = lkDescription) then
    Font.Color := $666666
  // Accent Color
  else if FUseAccentColor then
    Font.Color := SelectAccentColor(LCM, $D77800)
  // Light Color
  else if (LCM = nil) or (LCM.Colorization = ucLight) then
    Font.Color := clBlack
  // Dark Color
  else
    Font.Color := $FFFFFF;
end;

end.
