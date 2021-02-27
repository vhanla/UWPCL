unit UWP.Slider;

interface

uses
  Classes, Windows, Messages, Controls, Graphics, ExtCtrls,
  UWP.Classes, UWP.ColorManager, UWP.Colors, UWP.Utils;

type
  TUWPSlider = class(TCustomControl, IUWPControl)
  private
    var BarHeight: Integer;
    var CurWidth, CurHeight, CurCorner: Integer;
    var ActiveRect, NormalRect, CurRect: TRect;
    var AccentColor, BackColor, CurColor: TColor;

    FCustomBackColor: TUWPStateColorSet;
    FCustomCursorColor: TUWPStateColorSet;

    FIsSliding: Boolean;
    FAllowFocus: Boolean;
    FCanExit: Boolean;

    FControlState: TUWPControlState;
    FOrientation: TUWPOrientation;
    FMin: Integer;
    FMax: Integer;
    FValue: Integer;
    FPrevFocus: HWND;
    FFocusOnMouseEnter: Boolean;

    FMouseCaptureReleaser: TTimer;

    FOnChange: TNotifyEvent;

    // Internal
    procedure UpdateColors;
    procedure UpdateRects;

    // Setters
    procedure SetControlState(const AValue: TUWPControlState);
    procedure SetOrientation(const AValue: TUWPOrientation);
    procedure SetMin(const AValue: Integer);
    procedure SetMax(const AValue: Integer);
    procedure SetValue(const AValue: Integer);
    procedure SetAllowFocus(const AValue: Boolean);

    // Events for children
    procedure CustomBackColor_OnChange(Sender: TObject);
    procedure CustomCursorColor_OnChange(Sender: TObject);
    procedure MouseCaptureRelease_OnTimer(Sender: TObject);

    // Messages handling
    procedure WMSetFocus(var AMsg: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var AMsg: TWMKillFocus); message WM_KILLFOCUS;
    procedure CMExit(var AMsg: TWMNoParams); message CM_EXIT;

    procedure WMLButtonDown(var AMsg: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure WMLButtonUp(var AMsg: TWMLButtonUp); message WM_LBUTTONUP;
    procedure WMMouseMove(var AMsg: TWMMouseMove); message WM_MOUSEMOVE;
    procedure WMKeyDown(var AMsg: TWMKeyDown); message WM_KEYDOWN;
    procedure WMKeyUp(var AMsg: TWMKeyUp); message WM_KEYUP;

    procedure CMMouseEnter(var AMsg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var AMsg: TMessage); message CM_MOUSELEAVE;
//    procedure CMMOuseWheel(var AMsg: TCMMouseWheel); message CM_MOUSEWHEEL;

  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure ChangeScale(M, D: Integer; DpiChange: Boolean); override;


  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Interface
    function IsContainer: Boolean;
    procedure UpdateColorization(const IncludeChildren: Boolean);

    function DoMouseWheelDown(AShift: TShiftState; AMousePos: TPoint): Boolean; override;
    function DoMouseWheelUp(AShift: TShiftState; AMousePos: TPoint): Boolean; override;
    procedure MouseWheelHandler(var AMsg: TMessage); override;

  published
    property FocusOnMouseEnter: Boolean read FFocusOnMouseEnter write FFocusOnMouseEnter default False;
    property AllowFocus: Boolean read FAllowFocus write SetAllowFocus default True;
    property ControlState: TUWPControlState read FControlState write SetControlState default csNone;
    property CustomBackColor: TUWPStateColorSet read FCustomBackColor write FCustomBackColor;
    property CustomCursorColor: TUWPStateColorSet read FCustomCursorColor write FCustomCursorColor;

    property IsSliding: Boolean read FIsSliding;
    property Orientation: TUWPOrientation read FOrientation write SetOrientation default oHorizontal;
    property Min: Integer read FMin write SetMin default 0;
    property Max: Integer read FMax write SetMax default 100;
    property Value: Integer read FValue write SetValue default 0;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    // Modify default props
    property Height default 25;
    property Width default 100;

    //Enable props
    property Align;
    property Anchors;
    property AutoSize;
    property BiDiMode;
    property Color;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Touch;
    property Visible;
    property StyleElements;
    //Enable events
    property OnCanResize;
    property OnClick;
    property OnConstrainedResize;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGesture;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
end;

implementation

{ TUWPSlider }


{ TUWPSlider }

procedure TUWPSlider.ChangeScale(M, D: Integer; DpiChange: Boolean);
begin
  inherited;

  CurWidth := MulDiv(CurWidth, M, D);
  CurHeight := MulDiv(CurHeight, M, D);
  CurCorner := MulDiv(CurCorner, M, D);
  BarHeight := MulDiv(BarHeight, M, D);
  UpdateRects;
end;

procedure TUWPSlider.CMExit(var AMsg: TWMNoParams);
begin
  if FAllowFocus and not FCanExit then
  begin
    SetFocus;
  end;
  inherited;
end;

procedure TUWPSlider.CMMouseEnter(var AMsg: TMessage);
begin
  if not Enabled then Exit;
  ControlState := csHover;
  if not FIsSliding then
    MouseCapture := True;
//  if FFocusOnMouseEnter then
//    FPrevFocus := SetFocus(Parent.Handle);
  inherited;
end;

procedure TUWPSlider.CMMouseLeave(var AMsg: TMessage);
begin
  if not Enabled then Exit;
  ControlState := csNone;
  if not FIsSliding then
    MouseCapture := False;
  inherited;
end;

//procedure TUWPSlider.CMMOuseWheel(var AMsg: TCMMouseWheel);
//var
//  LValue: Integer;
//  LSign: Integer;
//begin
//  inherited;
//
//  if not PtInRect(GetClientRect, ScreenToClient(Mouse.CursorPos)) then
//    Exit;
//
//  if FIsSliding then Exit;
//
//  LSign := AMsg.WheelDelta div Abs(AMsg.WheelDelta);
//
//  if FOrientation = oHorizontal then
//  begin
//    LValue := LValue - LSign;
//  end
//  else
//  begin
//    LValue := LValue - LSign;
//  end;
//
//  // Keep it in range
//  if LValue < FMin then
//    LValue := FMin
//  else if LValue > FMax then
//    LValue := FMax;
//
//  Value := LValue;
//
//end;

constructor TUWPSlider.Create(AOwner: TComponent);
begin
  inherited;

  CurWidth := 8;
  CurHeight := 23;
  CurCorner := 5;
  BarHeight := 2;

  FIsSliding := False;
  FControlState := csNone;
  FOrientation := oHorizontal;
  FMin := 0;
  FMax := 100;
  FValue := 0;

  FAllowFocus := True;

  FCustomBackColor := TUWPStateColorSet.Create;
  FCustomBackColor.OnChange := CustomBackColor_OnChange;
  FCustomBackColor.Assign(SLIDER_BACK);

  FCustomCursorColor := TUWPStateColorSet.Create;
  FCustomCursorColor.OnChange := CustomCursorColor_OnChange;
  FCustomCursorColor.Assign(SLIDER_CURSOR);

  FFocusOnMouseEnter := False;
  FMouseCaptureReleaser := TTimer.Create(Self);
  FMouseCaptureReleaser.Interval := 100;
  FMouseCaptureReleaser.OnTimer := MouseCaptureRelease_OnTimer;

  // Modify default props
  Height := 25;
  Width := 100;
  TabStop := True;

  UpdateColors;
  UpdateRects;
end;

procedure TUWPSlider.CustomBackColor_OnChange(Sender: TObject);
begin
  UpdateColors;
  Invalidate;
end;

procedure TUWPSlider.CustomCursorColor_OnChange(Sender: TObject);
begin
  UpdateColors;
  Invalidate;
end;

destructor TUWPSlider.Destroy;
begin
  FMouseCaptureReleaser.Free;
  FCustomBackColor.Free;
  FCustomCursorColor.Free;
  inherited;
end;

function TUWPSlider.DoMouseWheelDown(AShift: TShiftState;
  AMousePos: TPoint): Boolean;
var
  LValue: Integer;
begin
  if FIsSliding then Exit;

  LValue := FValue - 1;

  // Keep it in range
//  if LValue < FMin then
//    LValue := FMin
//  else if LValue > FMax then
//    LValue := FMax;

  Value := LValue;
end;

function TUWPSlider.DoMouseWheelUp(AShift: TShiftState;
  AMousePos: TPoint): Boolean;
var
  LValue: Integer;
begin
  if FIsSliding then Exit;

  LValue := FValue + 1;

  // Keep it in range
//  if LValue < FMin then
//    LValue := FMin
//  else if LValue > FMax then
//    LValue := FMax;

  Value := LValue;

end;

function TUWPSlider.IsContainer: Boolean;
begin
  Result := False;
end;

procedure TUWPSlider.MouseCaptureRelease_OnTimer(Sender: TObject);
begin
  if MouseCapture then
  begin
    FMouseCaptureReleaser.Enabled := False;
    MouseCapture := False;
  end;
end;

procedure TUWPSlider.MouseWheelHandler(var AMsg: TMessage);
begin
  AMsg.Result := Perform(CM_MOUSEWHEEL, AMsg.WParam, AMsg.LParam);
  if AMsg.Result = 0 then
    inherited MouseWheelHandler(AMsg);
end;

procedure TUWPSlider.Paint;
begin
  inherited;

  // Draw active part
  Canvas.Brush.Handle := CreateSolidBrushWithAlpha(AccentColor, 255);
  Canvas.FillRect(ActiveRect);

  // Draw normal part
  Canvas.Brush.Handle := CreateSolidBrushWithAlpha(BackColor, 255);
  Canvas.FillRect(NormalRect);

  // Draw cursor
  Canvas.Pen.Color := CurColor;
  Canvas.Brush.Handle := CreateSolidBrushWithAlpha(CurColor, 255);
  Canvas.RoundRect(CurRect, CurCorner, CurCorner);
  Canvas.FloodFill(CurRect.Left + CurRect.Width div 2, CurRect.Top + CurRect.Height div 2,
    CurColor, fsSurface);
end;

procedure TUWPSlider.Resize;
begin
  inherited;
  UpdateRects;
end;

procedure TUWPSlider.SetAllowFocus(const AValue: Boolean);
begin
  if AValue <> FAllowFocus then
  begin
    FAllowFocus := AValue;
    UpdateColors;
    Invalidate;
  end;
end;

procedure TUWPSlider.SetControlState(const AValue: TUWPControlState);
begin
  if AValue <> FControlState then
  begin
    FControlState := AValue;
    UpdateColors;
    Invalidate;
  end;
end;

procedure TUWPSlider.SetMax(const AValue: Integer);
begin
  if AValue <> FMax then
  begin
    FMax := AValue;
    if FValue > FMax then
      FValue := FMax;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPSlider.SetMin(const AValue: Integer);
begin
  if AValue <> FMin then
  begin
    FMin := AValue;
    if FValue < FMin then
      FValue := FMin;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPSlider.SetOrientation(const AValue: TUWPOrientation);
var
  LSize: Integer;
begin
  if AValue <> FOrientation then
  begin
    FOrientation := AValue;

    // Switch CurWidth and CurHeight
    LSize := CurWidth;
    CurWidth := CurHeight;
    CurHeight := LSize;

    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPSlider.SetValue(const AValue: Integer);
begin
  if AValue <> FValue then
  begin
    if AValue < FMin then
      FValue := FMin
    else if AValue > FMax then
      FValue := FMax
    else
      FValue := AValue;

    if Assigned(FOnChange) then
      FOnChange(Self);

    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPSlider.UpdateColorization(const IncludeChildren: Boolean);
begin
  UpdateColors;
  UpdateRects;
  Invalidate;
end;

procedure TUWPSlider.UpdateColors;
var
  LCM: TUWPColorizationManager;
  LIsDark: Boolean;
  LBackColor: TUWPStateColorSet;
  LCurColor: TUWPStateColorSet;
begin
  LCM := SelectColorizationManager(Self);
  LIsDark := (LCM <> nil) and (LCM.Colorization = ucDark);

  if not Enabled then
  begin
    if not LIsDark then
      AccentColor := $CCCCCC
    else
      AccentColor := $333333;
    BackColor := AccentColor;
    CurColor := AccentColor;
  end
  else
  begin
    AccentColor := SelectAccentColor(LCM, $D77800);

    LBackColor := SelectColorSet(LCM, CustomBackColor, SLIDER_BACK);
    LCurColor := SelectColorSet(LCM, CustomCursorColor, SLIDER_CURSOR);

    BackColor := LBackColor.GetColor(LCM, ControlState, False);
    if ControlState = csNone then
      CurColor := AccentColor
    else
      CurColor := LCurColor.GetColor(LCM, ControlState, False);
  end;
end;

procedure TUWPSlider.UpdateRects;
begin
  if FOrientation = oHorizontal then
  begin
    ActiveRect.Left := 0;
    ActiveRect.Top := (Height - BarHeight) div 2;
    ActiveRect.Right := Round((Width - CurWidth) * (FValue - FMin) / (FMax - FMin));
    ActiveRect.Bottom := ActiveRect.Top + BarHeight;

    NormalRect.Left := ActiveRect.Right + 1;
    NormalRect.Top := ActiveRect.Top;
    NormalRect.Right := Width;
    NormalRect.Bottom := ActiveRect.Bottom;

    CurRect.Left := ActiveRect.Right;
    CurRect.Top := Height div 2 - CurHeight div 2;
    CurRect.Right := CurRect.Left + CurWidth;
    CurRect.Bottom := CurRect.Top + CurHeight;
  end
  else
  begin
    NormalRect.Left := (Width - BarHeight) div 2;
    NormalRect.Top := 0;
    NormalRect.Right := NormalRect.Left + BarHeight;
    NormalRect.Bottom := Round((Height - CurHeight) * (FMax - FValue) / (FMax - FMin));

    ActiveRect.Left := NormalRect.Left;
    ActiveRect.Top := NormalRect.Bottom + 1;
    ActiveRect.Right := NormalRect.Right;
    ActiveRect.Bottom := Height;

    CurRect.Left := (Width - CurWidth) div 2;
    CurRect.Top := NormalRect.Bottom;
    CurRect.Right := CurRect.Left + CurWidth;
    CurRect.Bottom := CurRect.Top + CurHeight;
  end;
end;

procedure TUWPSlider.WMKeyDown(var AMsg: TWMKeyDown);
begin
//  if MouseCapture then
//    MouseCapture := False;
//
//  if GetKeyState(VK_LEFT) and 128 = 128 then
//  begin
//    Value := Value - 1;
//
//  end
//  else if GetKeyState(VK_RIGHT) and 128 = 128 then
//  begin
//    Value := Value + 1;
//
//  end
//  else
    inherited;
end;

procedure TUWPSlider.WMKeyUp(var AMsg: TWMKeyUp);
begin
  if AMsg.CharCode = VK_LEFT then
  begin
    Value := Value - 2;
  end
  else if AMsg.CharCode = VK_RIGHT then
  begin
    Value := Value + 2;
  end
  else if AMsg.CharCode = VK_TAB then
  begin
    FCanExit := True;
  end
  //TODO: Needs fix to allow alt-f4 after mousecapture is set
  else if (HiWord(GetKeyState(VK_MENU)) <> 0) and (AMsg.CharCode = VK_F4) then
  begin
    FCanExit := True;
    MouseCapture := False;
  end
  else
  begin
    inherited;
  end;
end;

procedure TUWPSlider.WMKillFocus(var AMsg: TWMKillFocus);
begin
  if not Enabled then Exit;
  if AllowFocus then
  begin
    if not PtInRect(GetClientRect, ScreenToClient(Mouse.CursorPos)) then
      FCanExit := True;
    UpdateColors;
    Invalidate;
  end;
end;

procedure TUWPSlider.WMLButtonDown(var AMsg: TWMLButtonDown);
var
  LValue: Integer;
begin
  if not Enabled then Exit;

  if AllowFocus then
    SetFocus;

  FControlState := csPress;
  UpdateColors;
  FIsSliding := True;

  // If cursor is pressed
  if (AMsg.XPos < CurRect.Left)
  or (AMsg.XPos > CurRect.Right)
  or (AMsg.YPos < CurRect.Top)
  or (AMsg.YPos > CurRect.Bottom)
  then
  begin
    // Change FValue by click position
    if FOrientation = oHorizontal then
      LValue := FMin + Round((AMsg.XPos - CurWidth div 2) * (FMax - FMin) / (Width - CurWidth))
    else
      LValue := FMax - Round((AMsg.YPos - CurHeight div 2) * (FMax - FMin) / (Height - CurHeight));

    // Keep value in range [FMin..FMax]
//    if LValue < FMin then
//      FValue := FMin
//    else if LValue > FMax then
//      FValue := FMax;

    Value := LValue;
  end
  else
    Invalidate;

  inherited;
end;

procedure TUWPSlider.WMLButtonUp(var AMsg: TWMLButtonUp);
begin
  if not Enabled then Exit;
  FIsSliding  := False;
  ControlState := csNone;
  inherited;

  MouseCapture := True;
end;

procedure TUWPSlider.WMMouseMove(var AMsg: TWMMouseMove);
var
  LValue: Integer;
begin
  if not Enabled then Exit;

  if FIsSliding then
  begin
    if FOrientation = oHorizontal then
      LValue := FMin + Round((AMsg.XPos - CurWidth div 2) * (FMax - FMin) / (Width - CurWidth))
    else
      LValue := FMax - Round((AMsg.YPos - CurHeight div 2) * (FMax - FMin) / (Height - CurHeight));

    // Keep it in range
//    if LValue < FMin then
//      LValue := FMin
//    else if LValue > FMax then
//      LValue := FMax;

    Value := LValue;
  end
  else
  begin
    if MouseCapture and not PtInRect(ClientRect, SmallPointToPoint(AMsg.Pos)) then
    begin
      MouseCapture := False;
//      if FFocusOnMouseEnter then
//        SetFocus(FPrevFocus);
    end;
  end;

  inherited;
end;

procedure TUWPSlider.WMSetFocus(var AMsg: TWMSetFocus);
begin
  if not Enabled then Exit;
  if AllowFocus then
  begin
    SetFocus;
    FCanExit := False;
    UpdateColors;
    Invalidate;
  end;
end;

end.
