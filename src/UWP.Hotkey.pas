unit UWP.Hotkey;

interface

uses
  Classes, Windows, Messages, Controls, StdCtrls, ExtCtrls, Graphics, Forms,
  UWP.Classes, UWP.ColorManager, UWP.Utils, UWP.Graphics, UWP.Colors,
  ComCtrls, Vcl.Themes;

type
  TUWPHotkey = class(TCustomHotKey, IUWPControl)
  strict private
    class constructor Create;
    class destructor Destroy;
  private
    var BorderThickness: Integer;
    var BorderColor, BackColor, TextColor: TColor;

    FControlState: TUWPControlState;
    FCustomBackColor: TUWPColorizationColorSet;
    FCustomBorderColor: TUWPStateColorSet;

    FTransparent: Boolean;

    procedure UpdateColors;

    procedure SetControlState(const AValue: TUWPControlState);
    procedure SetTransparent(const AValue: Boolean);

    procedure CustomBackColor_OnChange(Sender: TObject);
    procedure CustomBorderColor_OnChange(Sender: TObject);

    procedure WMNCPaint(var AMsg: TWMNCPaint); message WM_NCPAINT;
    procedure WMLButtonDown(var AMsg: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure WMLButtonUp(var AMsg: TWMLButtonUp); message WM_LBUTTONUP;
    procedure WMSetFocus(var AMsg: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var AMsg: TWMKillFocus); message WM_KILLFOCUS;

    procedure CMMouseEnter(var AMsg: TMessage); message CM_MOUSEENTER;
    procedure CMMOuseLeave(var AMsg: TMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var AMsg: TMessage); message CM_ENABLEDCHANGED;

  protected
    procedure ChangeScale(M, D: Integer; DpiChanged: Boolean); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function IsContainer: Boolean;
    procedure UpdateColorization(const IncludeChildren: Boolean);

  published
    property ControlState: TUWPControlState read FControlState write SetControlState default csNone;
    property CustomBackColor: TUWPColorizationColorSet read FCustomBackColor write FCustomBackColor;
    property CustomBorderColor: TUWPStateColorSet read FCustomBorderColor write FCustomBorderColor;

    property Transparent: Boolean read FTransparent write SetTransparent default False;

    //property BorderStyle default bsNone;
    property BevelKind default bkFlat;
    property Ctl3D default False;
    property AutoSize default False;
    property Height default 30;

    property Anchors;
    property Align;
    property BiDiMode;
    property Constraints;
    property Enabled;
    property Hint;
    property HotKey;
    property InvalidKeys;
    property Modifiers;
    property ParentBiDiMode;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Touch;
    property Visible;
    property StyleElements;
    property OnChange;
    property OnContextPopup;
    property OnEnter;
    property OnExit;
    property OnGesture;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
  end;

implementation

{ TUWPHotkey }

class constructor TUWPHotkey.Create;
begin
  TCustomStyleEngine.RegisterStyleHook(TUWPHotKey, TEditStyleHook);
end;

class destructor TUWPHotkey.Destroy;
begin
  TCustomStyleEngine.UnRegisterStyleHook(TUWPHotKey, TEditStyleHook);
end;

procedure TUWPHotkey.ChangeScale(M, D: Integer; DpiChanged: Boolean);
begin
  inherited;
  BorderThickness := MulDiv(BorderThickness, M, D);
  BorderWidth := MulDiv(BorderWidth, M, D);
end;

procedure TUWPHotkey.CMEnabledChanged(var AMsg: TMessage);
begin
  UpdateColorization(False);
  inherited;
end;

procedure TUWPHotkey.CMMouseEnter(var AMsg: TMessage);
begin
  if not Enabled then Exit;
  ControlState := csNone;
  inherited;
end;

procedure TUWPHotkey.CMMOuseLeave(var AMsg: TMessage);
begin
  if not Enabled then Exit;
  ControlState := csNone;
  inherited;
end;

constructor TUWPHotkey.Create(AOwner: TComponent);
begin
  inherited;

  BorderThickness := 2;

  FControlState := csNone;
  FTransparent := False;

  FCustomBackColor := TUWPColorizationColorSet.Create;
  FCustomBackColor.OnChange := CustomBackColor_OnChange;
  FCustomBackColor.Assign(EDIT_BACK);

  FCustomBorderColor := TUWPStateColorSet.Create;
  FCustomBorderColor.OnChange := CustomBorderColor_OnChange;
  FCustomBorderColor.Assign(EDIT_BORDER);

  AutoSize := False;
  BevelKind := bkFlat;
  BorderWidth := 4;
  Ctl3D := False;
  Height := 30;

  UpdateColors;
end;

procedure TUWPHotkey.CustomBackColor_OnChange(Sender: TObject);
begin
  UpdateColorization(False);
end;

procedure TUWPHotkey.CustomBorderColor_OnChange(Sender: TObject);
begin
  UpdateColorization(False);
end;

destructor TUWPHotkey.Destroy;
begin
  FCustomBackColor.Free;
  FCustomBorderColor.Free;
  inherited;
end;

function TUWPHotkey.IsContainer: Boolean;
begin
  Result := False;
end;

procedure TUWPHotkey.SetControlState(const AValue: TUWPControlState);
begin
  if AValue <> FControlState then
  begin
    FControlState := AValue;
    UpdateColorization(False);
  end;
end;

procedure TUWPHotkey.SetTransparent(const AValue: Boolean);
begin
  if AValue <> FTransparent then
  begin
    FTransparent := AValue;
    UpdateColorization(False);
  end;
end;

procedure TUWPHotkey.UpdateColorization(const IncludeChildren: Boolean);
begin
  UpdateColors;

  if Color <> BackColor then
    Color := BackColor;

  ParentFont := True;
  if Font.Color <> TextColor then
    Font.Color := TextColor;
  Invalidate;
end;

procedure TUWPHotkey.UpdateColors;
var
  LCM: TUWPColorizationManager;
  LAccentColor: TColor;
  LBackColor: TUWPColorizationColorSet;
  LBorderColor: TUWPStateColorSet;
begin
  LCM := SelectColorizationManager(Self);
  LAccentColor := SelectAccentColor(LCM, $D77800);

  // disabled
  if not Enabled then
  begin
    BackColor := $D8D8D8;
    BorderColor := $CCCCCC;
    TextColor := clGray;
  end
  // enabled
  else
  begin
    if Transparent and (ControlState = csNone) then
    begin
      ParentColor := True;
      BackColor := Color;
    end
    else
    begin
      LBackColor := SelectColorSet(LCM, CustomBackColor, EDIT_BACK);
      BackColor := LBackColor.GetColor(LCM);
    end;

    if Focused or (ControlState = csPress) then
      BorderColor := LAccentColor
    else
    begin
      LBorderColor := SelectColorSet(LCM, CustomBorderColor, EDIT_BORDER);
      BorderColor := LBorderColor.GetColor(LCM, ControlState, Focused);
    end;

    TextColor := GetTextColorFromBackground(BackColor);
  end;

end;

procedure TUWPHotkey.WMKillFocus(var AMsg: TWMKillFocus);
begin
  UpdateColorization(False);
  Inherited;
end;

procedure TUWPHotkey.WMLButtonDown(var AMsg: TWMLButtonDown);
begin
  if not Enabled then Exit;
  ControlState := csPress;
  Inherited;
end;

procedure TUWPHotkey.WMLButtonUp(var AMsg: TWMLButtonUp);
var
  LMPos: TPoint;
begin
  if not Enabled then Exit;

  LMPos := ScreenToClient(Mouse.CursorPos);
  if PtInRect(GetClientRect, LMPos) then
    ControlState := csHover
  else
    ControlState := csNone;

  inherited;
end;

procedure TUWPHotkey.WMNCPaint(var AMsg: TWMNCPaint);
var
  LCanvas: TCanvas;
  LDC: HDC;
begin
  inherited;

  LDC := GetWindowDC(Handle);
  SaveDC(LDC);
  try
    LCanvas := TCanvas.Create;
    try
      LCanvas.Handle := LDC;
      LCanvas.Brush.Style := bsClear;

      DrawBorder(LCanvas, Rect(0, 0, Width, Height), BorderColor, BorderThickness);
    finally
      LCanvas.Free;
    end;
  finally
    RestoreDC(LDC, -1);
    ReleaseDC(Handle, LDC);
  end;
end;

procedure TUWPHotkey.WMSetFocus(var AMsg: TWMSetFocus);
begin
  UpdateColorization(False);
  inherited;
end;

end.
