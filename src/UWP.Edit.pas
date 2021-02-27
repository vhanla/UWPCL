unit UWP.Edit;

interface

uses
  Classes, Windows, Messages, Controls, StdCtrls, ExtCtrls, Graphics, Forms,
  UWP.Classes, UWP.ColorManager, UWP.Utils, UWP.Graphics, UWP.Colors;

type
  TUWPEdit = class(TEdit, IUWPControl)
  private
    var BorderThickness: Integer;
    var BorderColor, BackColor, TextColor: TColor;

    FControlState: TUWPControlState;
    FCustomBackColor: TUWPColorizationColorSet;
    FCustomBorderColor: TUWPStateColorSet;

    FTransparent: Boolean;

    // Internal
    procedure UpdateColors;

    // Setters
    procedure SetControlState(const AValue: TUWPControlState);
    procedure SetTransparent(const AValue: Boolean);

    // Events for children
    procedure CustomBackColor_OnChange(Sender: TObject);
    procedure CustomBorderColor_OnChange(Sender: TObject);

    // Messages handling
    procedure WMNCPaint(var AMsg: TWMNCPaint); message WM_NCPAINT;
    procedure WMLButtonDown(var AMsg: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure WMLButtonUp(var AMsg: TWMLButtonUp); message WM_LBUTTONUP;
    procedure WMKillFocus(var AMsg: TWMKillFocus); message WM_KILLFOCUS;

    procedure CMMouseEnter(var AMsg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var AMsg: TMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var AMsg: TMessage); message CM_ENABLEDCHANGED;

  protected
    procedure ChangeScale(M, D: Integer; DpiChanged: Boolean); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Interface
    function IsContainer: Boolean;
    procedure UpdateColorization(const IncludeChildren: Boolean);

  published
    property ControlState: TUWPControlState read FControlState write SetControlState default csNone;
    property CustomBackColor: TUWPColorizationColorSet read FCustomBackColor write FCustomBackColor;
    property CustomBorderColor: TUWPStateColorSet read FCustomBorderColor write FCustomBorderColor;

    property Transparent: Boolean read FTransparent write SetTransparent default False;

    // Modify default props
    property BorderStyle default bsNone;
    property BevelKind default bkFlat;
    property Ctl3D default False;
    property AutoSize default False;
    property Height default 30;
  end;

implementation

{ TUWPEdit }

procedure TUWPEdit.ChangeScale(M, D: Integer; DpiChanged: Boolean);
begin
  inherited;
  BorderThickness := MulDiv(BorderThickness, M, D);
  BorderWidth := MulDiv(BorderWidth, M, D);
end;

procedure TUWPEdit.CMEnabledChanged(var AMsg: TMessage);
begin
  UpdateColorization(False);
  inherited;
end;

procedure TUWPEdit.CMMouseEnter(var AMsg: TMessage);
begin
  if not Enabled then Exit;
  ControlState := csHover;
  inherited;
end;

procedure TUWPEdit.CMMouseLeave(var AMsg: TMessage);
begin
  if not Enabled then Exit;
  ControlState := csNone;
  inherited;
end;

constructor TUWPEdit.Create(AOwner: TComponent);
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

  // Modify default props
  AutoSize := False;
  BorderStyle := bsNone;
  BevelKind := bkFlat;
  BorderWidth := 4;
  Ctl3D := False;
  Height := 30;

  UpdateColors;
end;

procedure TUWPEdit.CustomBackColor_OnChange(Sender: TObject);
begin
  UpdateColorization(False);
end;

procedure TUWPEdit.CustomBorderColor_OnChange(Sender: TObject);
begin
  UpdateColorization(False);
end;

destructor TUWPEdit.Destroy;
begin
  FCustomBackColor.Free;
  FCustomBorderColor.Free;
  inherited;
end;

function TUWPEdit.IsContainer: Boolean;
begin
  Result := False;
end;

procedure TUWPEdit.SetControlState(const AValue: TUWPControlState);
begin
  if AValue <> FControlState then
  begin
    FControlState := AValue;
    UpdateColorization(False);
  end;
end;

procedure TUWPEdit.SetTransparent(const AValue: Boolean);
begin
  if AValue <> FTransparent then
  begin
    FTransparent := AValue;
    UpdateColorization(False);
  end;
end;

procedure TUWPEdit.UpdateColorization(const IncludeChildren: Boolean);
begin
  UpdateColors;

  if Color <> BackColor then
    Color := BackColor;

  ParentFont := True;
  if Font.Color <> TextColor then
    Font.Color := TextColor;
  Invalidate;
end;

procedure TUWPEdit.UpdateColors;
var
  LCM: TUWPColorizationManager;
  LAccentColor: TColor;
  LBackColor: TUWPColorizationColorSet;
  LBorderColor: TUWPStateColorSet;
begin
  LCM := SelectColorizationManager(Self);
  LAccentColor := SelectAccentColor(LCM, $D77800);

  if not Enabled then
  begin
    BackColor := $D8D8D8;
    BorderColor :=$CCCCCC;
    TextColor := clGray;
  end
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
    begin
      BorderColor := LAccentColor;
    end
    else
    begin
      LBorderColor := SelectColorSet(LCM, CustomBorderColor, EDIT_BORDER);
      BorderColor := LBorderColor.GetColor(LCM, ControlState, Focused);
    end;

    TextColor := GetTextColorFromBackground(BackColor);
  end;
end;

procedure TUWPEdit.WMKillFocus(var AMsg: TWMKillFocus);
begin
  UpdateColorization(False);
  inherited;
end;

procedure TUWPEdit.WMLButtonDown(var AMsg: TWMLButtonDown);
begin
  if not Enabled then Exit;
  ControlState := csPress;
  inherited;
end;

procedure TUWPEdit.WMLButtonUp(var AMsg: TWMLButtonUp);
var
  LMousePos: TPoint;
begin
  if not Enabled then Exit;

  LMousePos := ScreenToClient(Mouse.CursorPos);
  if PtInRect(GetClientRect, LMousePos) then
    ControlState := csHover
  else
    ControlState := csNone;

  inherited;
end;

procedure TUWPEdit.WMNCPaint(var AMsg: TWMNCPaint);
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
      //LCanvas.Brush.Style := bsClear;
      LCanvas.Brush.Style := bsSolid;

      DrawBorder(LCanvas, Rect(0, 0, Width, Height), BorderColor, BorderThickness);
    finally
      LCanvas.Free;
    end;
  finally
    RestoreDC(LDC, -1);
    ReleaseDC(Handle, LDC);
  end;
end;

end.
