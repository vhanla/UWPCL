unit UWP.Colors;

interface

uses
  Classes, Graphics, Controls,
  UWP.Classes, UWP.ColorManager;

type
  TUWPColorizationColorSet = class(TPersistent)
  private
    FEnabled: Boolean;
    FColor: TColor;
    FLightColor: TColor;
    FDarkColor: TColor;
    FOnChange: TNotifyEvent;

    procedure SetEnabled(const AValue: Boolean);
    procedure SetColorizationColor(Index: Integer; const AValue: TColor);

  protected
    procedure Changed;

  public
    constructor Create; overload;
    constructor Create(AColor, ALightColor, ADarkColor: TColor); overload;
    procedure Assign(ASource: TPersistent); override;

    procedure SetColor(AColor, ALightColor, ADarkColor: TColor);
    function GetColor(const AColorizationManager: TUWPColorizationManager): TColor;

  published
    property Enabled: Boolean read FEnabled write SetEnabled;

    property Color: TColor index 0 read FColor write SetColorizationColor;
    property LightColor: TColor index 1 read FLightColor write SetColorizationColor;
    property DarkColor: TColor index 2 read FDarkColor write SetColorizationColor;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TUWPStateColorSet = class(TPersistent)
  private
    FEnabled: Boolean;

    FLightNone: TColor;
    FLightHover: TColor;
    FLightPress: TColor;
    FLightSelectedNone: TColor;
    FLightSelectedHover: TColor;
    FLightSelectedPress: TColor;

    FDarkNone: TColor;
    FDarkHover: TColor;
    FDarkPress: TColor;
    FDarkSelectedNone: TColor;
    FDarkSelectedHover: TColor;
    FDarkSelectedPress: TColor;

    FOnchage: TNotifyEvent;

    procedure SetEnabled(const AValue: Boolean);
    procedure SetStateColor(Index: Integer; const AValue: TColor);

  protected
    procedure Changed;

  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;

    procedure SetLightColor(None, Hover, Press, SNone, SHover, SPress: TColor);
    procedure SetDarkColor(None, Hover, Press, SNone, SHover, SPress: TColor);
    function GetColor(const AColorizationManager: TUWPColorizationManager; AState: TUWPControlState; IsSelected: Boolean): TColor;

  published
    property Enabled: Boolean read FEnabled write SetEnabled;

    property LightNone: TColor index 0 read FLightNone write SetStateColor;
    property LightHover: TColor index 1 read FLightHover write SetStateColor;
    property LightPress: TColor index 2 read FLightPress write SetStateColor;
    property LightSelectedNone: TColor index 3 read FLightSelectedNone write SetStateColor;
    property LightSelectedHover: TColor index 4 read FLightSelectedHover write SetStateColor;
    property LightSelectedPress: TColor index 5 read FLightSelectedPress write SetStateColor;

    property DarkNone: TColor index 6 read FDarkNone write SetStateColor;
    property DarkHover: TColor index 7 read FDarkHover write SetStateColor;
    property DarkPress: TColor index 8 read FDarkPress write SetStateColor;
    property DarkSelectedNone: TColor index 9 read FDarkSelectedNone write SetStateColor;
    property DarkSelectedHover: TColor index 10 read FDarkSelectedHover write SetStateColor;
    property DarkSelectedPress: TColor index 11 read FDarkSelectedPress write SetStateColor;

    property OnChange: TNotifyEvent read FOnchage write FOnchage;
  end;

var
  // ToolTip
  TOOLTIP_SHADOW: Boolean;
  TOOLTIP_BORDER_THICKNESS: Byte;
  TOOLTIP_FONT_NAME: string;
  TOOLTIP_FONT_SIZE: Byte;
  TOOLTIP_BACK: TUWPColorizationColorSet;
  TOOLTIP_BORDER: TUWPColorizationColorSet;

  // Form
  FORM_FONT_NAME: string;
  FORM_FONT_SIZE: Byte;
  FORM_BACK: TUWPColorizationColorSet;

  // Popup Menu
  POPUP_BACK: TUWPColorizationColorSet;

  // Progress Bar
  PROGRESSBAR_BACK: TUWPColorizationColorSet;

  // Panel
  PANEL_BACK: TUWPColorizationColorSet;

  // ScrollBox
  SCROLLBOX_BACK: TUWPColorizationColorSet;

  // Caption Bar
  CAPTIONBAR_BACK: TUWPColorizationColorSet;

  // Button
  BUTTON_BACK: TUWPStateColorSet;
  BUTTON_BORDER: TUWPStateColorSet;

  // List Button
  LISTBUTTON_BACK: TUWPStateColorSet;

  // Quick Button
  QUICKBUTTON_BACK: TUWPColorizationColorSet;

  // Slider
  SLIDER_BACK: TUWPStateColorSet;
  SLIDER_CURSOR: TUWPStateColorSet;

  // HyperLink
  HYPERLINK_FONT_NAME: string;
  HYPERLINK_FONT_SIZE: Byte;
  HYPERLINK_TEXT_COLOR: TUWPStateColorSet;

  // Edit
  EDIT_BACK: TUWPColorizationColorSet;
  EDIT_BORDER: TUWPStateColorSet;

  // Hotkey
  HOTKEY_BACK: TUWPColorizationColorSet;
  HOTKEY_BORDER: TUWPColorizationColorSet;

  // ComboBox
  COMBOBOX_BACK: TUWPColorizationColorSet;
  COMBOBOX_BORDER: TUWPColorizationColorSet;

  // ListBox
  LISTBOX_BACK: TUWPColorizationColorSet;
  LISTBOX_BORDER: TUWPColorizationColorSet;

  // SpinEdit
  SPINEDIT_BACK: TUWPColorizationColorSet;
  SPINEDIT_BORDER: TUWPColorizationColorSet;

// color utils
function SelectColorizationManager(AControl: TControl): TUWPColorizationManager;
function SelectColorSet(const ACM: TUWPColorizationManager;
  ACustomColorSet, ADefaultColorSet: TUWPColorizationColorSet): TUWPColorizationColorSet; overload;
function SelectColorSet(const ACM: TUWPColorizationManager;
  ACustomColorSet, ADefaultColorSet: TUWPStateColorSet): TUWPStateColorSet; overload;
function SelectAccentColor(const ACM: TUWPColorizationManager;
  ACustomAccentColor: TColor): TColor;

implementation

uses
  Forms, UWP.Form;

{ TUWPColorizationColorSet }

procedure TUWPColorizationColorSet.Assign(ASource: TPersistent);
begin
  if ASource is TUWPColorizationColorSet then
  begin
    FEnabled := TUWPColorizationColorSet(ASource).Enabled;
    FColor := TUWPColorizationColorSet(ASource).Color;
    FLightColor := TUWPColorizationColorSet(ASource).LightColor;
    FDarkColor := TUWPColorizationColorSet(ASource).DarkColor;
  end
  else
    inherited;
end;

procedure TUWPColorizationColorSet.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

constructor TUWPColorizationColorSet.Create(AColor, ALightColor,
  ADarkColor: TColor);
begin
  inherited Create;
  SetColor(AColor, ALightColor, ADarkColor);
end;

constructor TUWPColorizationColorSet.Create;
begin
  inherited;
  FEnabled := False;
  FColor := clBtnFace;
  FLightColor := $FFFFFF;
  FDarkColor := 0;
end;

function TUWPColorizationColorSet.GetColor(
  const AColorizationManager: TUWPColorizationManager): TColor;
begin
  if AColorizationManager = nil then
    Result := Color
  else if AColorizationManager.Colorization = ucLight then
    Result := LightColor
  else
    Result := DarkColor;
end;

procedure TUWPColorizationColorSet.SetColor(AColor, ALightColor,
  ADarkColor: TColor);
begin
  FColor := AColor;
  FLightColor := ALightColor;
  FDarkColor := ADarkColor;
  Changed;
end;

procedure TUWPColorizationColorSet.SetColorizationColor(Index: Integer;
  const AValue: TColor);
begin
  case Index of
    0:
      if AValue <> FColor then
        FColor := AValue;
    1:
      if AValue <> FLightColor then
        FLightColor := AValue;
    2:
      if AValue <> FDarkColor then
        FDarkColor := AValue;
  end;

  if Index in [0..2] then
    Changed;
end;

procedure TUWPColorizationColorSet.SetEnabled(const AValue: Boolean);
begin
  if AValue <> FEnabled then
  begin
    FEnabled := AValue;
    Changed;
  end;
end;

{ TUWPStateColorSet }

procedure TUWPStateColorSet.Assign(ASource: TPersistent);
begin
  if ASource is TUWPStateColorSet then
  begin
    FEnabled := TUWPStateColorSet(ASource).Enabled;

    FLightNone := TUWPStateColorSet(ASource).LightNone;
    FLightHover := TUWPStateColorSet(ASource).LightHover;
    FLightPress := TUWPStateColorSet(ASource).LightPress;
    FLightSelectedNone := TUWPStateColorSet(ASource).LightSelectedNone;
    FLightSelectedHover := TUWPStateColorSet(ASource).LightSelectedHover;
    FLightSelectedPress := TUWPStateColorSet(ASource).LightSelectedPress;

    FDarkNone := TUWPStateColorSet(ASource).DarkNone;
    FDarkHover := TUWPStateColorSet(ASource).DarkHover;
    FDarkPress := TUWPStateColorSet(ASource).DarkPress;
    FDarkSelectedNone := TUWPStateColorSet(ASource).DarkSelectedNone;
    FDarkSelectedHover := TUWPStateColorSet(ASource).DarkSelectedHover;
    FDarkSelectedPress := TUWPStateColorSet(ASource).DarkSelectedPress;
  end
  else
    inherited;
end;

procedure TUWPStateColorSet.Changed;
begin
  if Assigned(FOnchage) then
    FOnchage(Self);
end;

constructor TUWPStateColorSet.Create;
begin
  inherited;
  FEnabled := False;
  FLightNone := $F2F2F2;
  FLightHover := $E6E6E6;
  FLightPress := $CCCCCC;
  FLightSelectedNone := $F2F2F2;
  FLightSelectedHover := $E6E6E6;
  FLightSelectedPress := $CCCCCC;
  FDarkNone := $2B2B2B;
  FDarkHover := $333333;
  FDarkPress := $3B3B3B;
  FDarkSelectedNone := $2B2B2B;
  FDarkSelectedHover := $333333;
  FDarkSelectedPress := $3B3B3B;
end;

function TUWPStateColorSet.GetColor(
  const AColorizationManager: TUWPColorizationManager; AState: TUWPControlState;
  IsSelected: Boolean): TColor;
var
  ResultCode: Byte;
begin
  ResultCode := 0;

  if (AColorizationManager <> nil) and (AColorizationManager.Colorization = ucDark) then
    Inc(ResultCode, 6); // shift to dark color index

  if IsSelected then
    Inc(ResultCode, 3); // shift to selected index

  Inc(ResultCode, Ord(AState));

  case ResultCode of
    0: Result := LightNone;
    1: Result := LightHover;
    2: Result := LightPress;
    3: Result := LightSelectedNone;
    4: Result := LightSelectedHover;
    5: Result := LightSelectedPress;
    // dark ones shifted by 6 index
    6: Result := DarkNone;
    7: Result := DarkHover;
    8: Result := DarkPress;
    9: Result := DarkSelectedNone;
    10: Result := DarkSelectedHover;
    11: Result := DarkSelectedPress;
    else
      Result := 0;
  end;


end;

procedure TUWPStateColorSet.SetDarkColor(None, Hover, Press, SNone, SHover,
  SPress: TColor);
begin
  FDarkNone := None;
  FDarkHover := Hover;
  FDarkPress := Press;
  FDarkSelectedNone := SNone;
  FDarkSelectedHover := SHover;
  FDarkSelectedPress := SPress;
  Changed;
end;

procedure TUWPStateColorSet.SetEnabled(const AValue: Boolean);
begin
  if AValue <> FEnabled then
  begin
    FEnabled := AValue;
    Changed;
  end;
end;

procedure TUWPStateColorSet.SetLightColor(None, Hover, Press, SNone, SHover,
  SPress: TColor);
begin
  FLightNone := None;
  FLightHover := Hover;
  FLightPress := Press;
  FLightSelectedNone := SNone;
  FLightSelectedHover := SHover;
  FLightSelectedPress := SPress;
  Changed;
end;

procedure TUWPStateColorSet.SetStateColor(Index: Integer; const AValue: TColor);
begin
  case Index of
    0: if AValue <> FLightNone then
      FLightNone := AValue;
    1: if AValue <> FLightHover then
      FLightHover := AValue;
    2: if AValue <> FLightPress then
      FLightPress := AValue;
    3: if AValue <> FLightSelectedNone then
      FLightSelectedNone := AValue;
    4: if AValue <> FLightSelectedHover then
      FLightSelectedHover := Avalue;
    5: if AValue <> FLightSelectedPress then
      FLightSelectedPress := AValue;
    6: if AValue <> FDarkNone then
      FDarkNone := AValue;
    7: if AValue <> FDarkHover then
      FDarkHover := AValue;
    8: if AValue <> FDarkPress then
      FDarkPress := AValue;
    9: if AValue <> FDarkSelectedNone then
      FDarkSelectedNone := AValue;
    10: if AValue <> FDarkSelectedHover then
      FDarkSelectedHover := AValue;
    11: if AValue <> FDarkSelectedPress then
      FDarkSelectedPress := AValue;
  end;
end;

{ Color Utils}
function SelectColorizationManager(AControl: TControl): TUWPColorizationManager;
var
  LParentForm: TCustomForm;
begin
  LParentForm := GetParentForm(AControl, True);
  if (LParentForm <> nil) and (LParentForm is TUWPForm) then
    Result := TUWPForm(LParentForm).ColorizationManager
  else
    Result := nil;
end;

function SelectColorSet(const ACM: TUWPColorizationManager;
  ACustomColorSet, ADefaultColorSet: TUWPColorizationColorSet): TUWPColorizationColorSet; overload;
begin
  if ACustomColorSet = nil then Exit(nil);

  if(ACM = nil) or (ACustomColorSet.Enabled) then
    Result := ACustomColorSet
  else
    Result := ADefaultColorSet;
end;

function SelectColorSet(const ACM: TUWPColorizationManager;
  ACustomColorSet, ADefaultColorSet: TUWPStateColorSet): TUWPStateColorSet; overload;
begin
  if ACustomColorSet = nil then Exit(nil);

  if(ACM = nil) or (ACustomColorSet.Enabled) then
    Result := ACustomColorSet
  else
    Result := ADefaultColorSet;
end;

function SelectAccentColor(const ACM: TUWPColorizationManager;
  ACustomAccentColor: TColor): TColor;
begin
  if ACM = nil then
    Result := ACustomAccentColor
  else
    Result := ACM.AccentColor;
end;


initialization
  // ToolTip
  TOOLTIP_SHADOW := False;
  TOOLTIP_BORDER_THICKNESS := 1;
  TOOLTIP_FONT_NAME := 'Segoe UI';
  TOOLTIP_FONT_SIZE := 8;
  TOOLTIP_BACK := TUWPColorizationColorSet.Create(0, $F2F2F2, $2B2B2B);
  TOOLTIP_BORDER := TUWPColorizationColorSet.Create(0, $CCCCCC, $767676);

  // Form
  FORM_FONT_NAME := 'Segoe UI';
  FORM_FONT_SIZE := 10;
  FORM_BACK := TUWPColorizationColorSet.Create(0, $FFFFFF, 0);

  // Popup Menu
  POPUP_BACK := TUWPColorizationColorSet.Create($E6E6E6, $E6E6E6, $1F1F1F);

  // Progress Bar
  PROGRESSBAR_BACK := TUWPColorizationColorSet.Create($E6E6E6, $CCCCCC, $333333);

  // Panel
  PANEL_BACK := TUWPColorizationColorSet.Create($E6E6E6, $E6E6E6, $1F1F1F);

  // ScrollBox
  SCROLLBOX_BACK := TUWPColorizationColorSet.Create($E6E6E6, $E6E6E6, $1F1F1F);

  // Caption Bar
  CAPTIONBAR_BACK := TUWPColorizationColorSet.Create($F2F2F2, $F2F2F2, $2B2B2B);

  // Button
  BUTTON_BACK := TUWPStateColorSet.Create;
  BUTTON_BACK.SetLightColor($CCCCCC, $CCCCCC, $999999, $CCCCCC, $CCCCCC, $999999);
  BUTTON_BACK.SetDarkColor($333333, $333333, $666666, $333333, $333333, $666666);
  BUTTON_BORDER := TUWPStateColorSet.Create;
  BUTTON_BORDER.SetLightColor($CCCCCC, $7A7A7A, $999999, $7A7A7A, $7A7A7A, $999999);
  BUTTON_BORDER.SetDarkColor($333333, $858585, $666666, $858585, $858585, $666666);

  // ListButton
  LISTBUTTON_BACK := TUWPStateColorSet.Create;
  LISTBUTTON_BACK.SetLightColor($E6E6E6, $CFCFCF, $888888, 127, 103, 89);
  LISTBUTTON_BACK.SetDarkColor($1F1F1F, $353535, $4C4C4C, 89, 103, 127);

  // QuickButton
  QUICKBUTTON_BACK := TUWPColorizationColorSet.Create(0, $CFCFCF, $3C3C3C);

  // Slider
  SLIDER_BACK := TUWPStateColorSet.Create;
  SLIDER_BACK.SetLightColor($999999, $666666, $999999, $999999, $666666, $999999);
  SLIDER_BACK.SetDarkColor($666666, $999999, $666666, $666666, $999999, $666666);
  SLIDER_CURSOR := TUWPStateColorSet.Create;
  SLIDER_CURSOR.SetLightColor($D77800, $171717, $CCCCCC, $D77800, $171717, $CCCCCC);
  SLIDER_CURSOR.SetDarkColor($D77800, $F2F2F2, $767676, $D77800, $F2F2F2, $767676);

  // HyperLink
  HYPERLINK_FONT_NAME := 'Segoe UI';
  HYPERLINK_FONT_SIZE := 10;
  HYPERLINK_TEXT_COLOR := TUWPStateColorSet.Create;
  HYPERLINK_TEXT_COLOR.SetLightColor($D77800, clGray, clMedGray, $D77800, clGray, clMedGray);
  HYPERLINK_TEXT_COLOR.SetDarkColor($D77800, clMedGray, clGray, $D77800, clMedGray, clGray);

  // Edit
  EDIT_BACK := TUWPColorizationColorSet.Create($FFFFFF, $FFFFFF, 0);
  EDIT_BORDER := TUWPStateColorSet.Create;
  EDIT_BORDER.SetLightColor($999999, $666666, $D77800, $D77800, $D77800, $D77800);
  EDIT_BORDER.SetDarkColor($666666, $999999, $D77800, $D77800, $D77800, $D77800);

finalization

  TOOLTIP_BACK.Free;
  TOOLTIP_BORDER.Free;

  FORM_BACK.Free;

  POPUP_BACK.Free;

  PROGRESSBAR_BACK.Free;

  PANEL_BACK.Free;

  SCROLLBOX_BACK.Free;

  CAPTIONBAR_BACK.Free;

  BUTTON_BACK.Free;
  BUTTON_BORDER.Free;

  LISTBUTTON_BACK.Free;

  QUICKBUTTON_BACK.Free;

  SLIDER_BACK.Free;
  SLIDER_CURSOR.Free;

  HYPERLINK_TEXT_COLOR.Free;

  EDIT_BACK.Free;
  EDIT_BORDER.Free;

end.
