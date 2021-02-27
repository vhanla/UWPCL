unit UWP.Button;

interface

uses
  Classes, Types, Windows, Messages, Controls, Graphics, ImgList, Forms,
  UWP.Classes, UWP.ColorManager, UWP.Graphics, UWP.Utils, UWP.Colors;

type
  TUWPButton = class(TCustomControl, IUWPControl)
  private
    var BorderThickness: Integer;
    var BorderColor, BackColor, TextColor: TColor;
    var ImgRect, TextRect: TRect;

    FButtonState: TUWPControlState;
    FCustomBackColor: TUWPStateColorSet;
    FCustomBorderColor: TUWPStateColorSet;

    FAlignment: TAlignment;
    FImages: TCustomImageList;
    FImageIndex: Integer;
    FAllowFocus: Boolean;
    FHighlight: Boolean;
    FIsToggleButton: Boolean;
    FIsToggled: Boolean;
    FTransparent: Boolean;

    // Internal
    procedure UpdateColors;
    procedure UpdateRects;

    // Setters
    procedure SetButtonState(const AValue: TUWPControlState);
    procedure SetAlignment(const AValue: TAlignment);
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetImageIndex(const AValue: Integer);
    procedure SetAllowFocus(const AValue: Boolean);
    procedure SetHightight(const AValue: Boolean);
    procedure SetIsToggleButton(const AValue: Boolean);
    procedure SetIsToggled(const AValue: Boolean);
    procedure SetTransparent(const AValue: Boolean);

    // Events for children
    procedure CustomBackColor_OnChange(Sender: TObject);
    procedure CustomBorderColor_OnChange(Sender: TObject);

    // Message handling
    procedure WMSetFocus(var AMsg: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var AMsg: TWMKillFocus); message WM_KILLFOCUS;

    procedure WMLButtonDown(var AMsg: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure WMLButtonUp(var AMsg: TWMLButtonUp); message WM_LBUTTONUP;

    procedure CMMouseEnter(var AMsg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var AMsg: TMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var AMsg: TMessage); message CM_ENABLEDCHANGED;
    procedure CMDialogKey(var AMsg: TCMDialogKey); message CM_DIALOGKEY;
    procedure CMTextChanged(var AMsg: TMessage); message CM_TEXTCHANGED;

  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure CreateWindowHandle(const AParams: TCreateParams); override;
    procedure ChangeScale(M, D: Integer; DpiChanged: Boolean); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Interface
    function IsContainer: Boolean;
    procedure UpdateColorization(const IncludeChildren: Boolean);

  published
    property ButtonState: TUWPControlState read FButtonState write SetButtonState default csNone;
    property CustomBackColor: TUWPStateColorSet read FCustomBackColor write FCustomBackColor;
    property CustomBorderColor: TUWPStateColorSet read FCustomBorderColor write FCustomBorderColor;

    property Alignment: TAlignment read FAlignment write SetAlignment default taCenter;
    property Images: TCustomImageList read FImages write SetImages;
    property ImageIndex: Integer read FImageIndex write SetImageIndex default -1;
    property AllowFocus: Boolean read FAllowFocus write SetAllowFocus default True;
    property Highlight: Boolean read FHighlight write SetHightight default False;
    property IsToggleButton: Boolean read FIsToggleButton write SetIsToggleButton default False;
    property IsToggled: Boolean read FIsToggled write SetIsToggled default False;
    property Transparent: Boolean read FTransparent write SetTransparent default False;

    // Modify default props
    property Height default 30;
    property Width default 135;
    property TabStop default True;

    // Enable props
    property Align;
    property Anchors;
    property AutoSize;
    property BiDiMode;
    property Caption;
    //property Color;
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
    property Touch;
    property Visible;
    // Enable events
    property OnCanResize;
    property OnClick;
    property OnConstrainedResize;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnGesture;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
  end;

implementation

{ TUWPButton }

procedure TUWPButton.ChangeScale(M, D: Integer; DpiChanged: Boolean);
begin
  inherited;
  BorderThickness := MulDiv(BorderThickness, M, D);
  UpdateRects;
end;

procedure TUWPButton.CMDialogKey(var AMsg: TCMDialogKey);
begin
  if AllowFocus and Focused and (AMsg.CharCode = VK_RETURN) then
  begin
    Click;
    AMsg.Result := 1;
  end
  else
    inherited;
end;

procedure TUWPButton.CMEnabledChanged(var AMsg: TMessage);
begin
  inherited;
  UpdateColors;
  Invalidate;
end;

procedure TUWPButton.CMMouseEnter(var AMsg: TMessage);
begin
  if not Enabled then Exit;
  ButtonState := csHover;
  inherited;
end;

procedure TUWPButton.CMMouseLeave(var AMsg: TMessage);
begin
  if not Enabled then Exit;
  ButtonState := csNone;
  inherited;
end;

procedure TUWPButton.CMTextChanged(var AMsg: TMessage);
begin
  inherited;
  Invalidate;
end;

constructor TUWPButton.Create(AOwner: TComponent);
begin
  inherited;

  ControlStyle := ControlStyle - [csDoubleClicks];

  BorderThickness := 2;

  FButtonState := csNone;
  FAlignment := taCenter;
  FImageIndex := -1;
  FAllowFocus := True;
  FHighlight :=False;
  FIsToggleButton := False;
  FIsToggled := False;
  FTransparent := False;

  FCustomBackColor := TUWPStateColorSet.Create;
  FCustomBackColor.OnChange := CustomBackColor_OnChange;
  FCustomBackColor.Assign(BUTTON_BACK);

  FCustomBorderColor := TUWPStateColorSet.Create;
  FCustomBorderColor.OnChange := CustomBorderColor_OnChange;
  FCustomBorderColor.Assign(BUTTON_BORDER);

  // Modify default props
  Height := 30;
  Width := 135;
  TabStop := True;
end;

procedure TUWPButton.CreateWindowHandle(const AParams: TCreateParams);
begin
  inherited;
  UpdateColors;
  UpdateRects;
end;

procedure TUWPButton.CustomBackColor_OnChange(Sender: TObject);
begin
  UpdateColors;
  Invalidate;
end;

procedure TUWPButton.CustomBorderColor_OnChange(Sender: TObject);
begin
  UpdateColors;
  Invalidate;
end;

destructor TUWPButton.Destroy;
begin
  FCustomBackColor.Free;
  FCustomBorderColor.Free;
  inherited;
end;

function TUWPButton.IsContainer: Boolean;
begin
  Result := False;
end;

procedure TUWPButton.Paint;
var
  LImgX, LImgY: Integer;
begin
  inherited;

  // Draw background
  Canvas.Brush.Handle := CreateSolidBrushWithAlpha(BackColor, 255);
  Canvas.FillRect(Rect(0, 0, Width, Height));

  // Draw Border
  DrawBorder(Canvas, Rect(0, 0, Width, Height), BorderColor, BorderThickness);

  // Draw Image
  if (Images <> nil) and (ImageIndex >= 0) then
  begin
    GetCenterPos(Images.Width, Images.Height, ImgRect, LImgX, LImgY);
    Images.Draw(Canvas, LImgX, LImgY, ImageIndex, Enabled);
  end;

  // Draw Text
  Canvas.Font.Assign(Font);
  Canvas.Font.Color := TextColor;
  DrawTextRect(Canvas, Alignment, taVerticalCenter, TextRect, Caption, False);
end;

procedure TUWPButton.Resize;
begin
  inherited;
  UpdateRects;
end;

procedure TUWPButton.SetAlignment(const AValue: TAlignment);
begin
  if AValue <> FAlignment then
  begin
    FAlignment := AValue;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPButton.SetAllowFocus(const AValue: Boolean);
begin
  if AValue <> FAllowFocus then
  begin
    FAllowFocus := AValue;
    UpdateColors;
    Invalidate;
  end;
end;

procedure TUWPButton.SetButtonState(const AValue: TUWPControlState);
begin
  if AValue <> FButtonState then
  begin
    FButtonState := AValue;
    UpdateColors;
    Invalidate;
  end;
end;

procedure TUWPButton.SetHightight(const AValue: Boolean);
begin
  if AValue <> FHighlight then
  begin
    FHighlight := AValue;
    UpdateColors;
    Invalidate;
  end;
end;

procedure TUWPButton.SetImageIndex(const AValue: Integer);
begin
  if AValue <> FImageIndex then
  begin
    FImageIndex := AValue;
    UpdateColors;
    Invalidate;
  end;
end;

procedure TUWPButton.SetImages(const AValue: TCustomImageList);
begin
  if AValue <> FImages then
  begin
    FImages := AValue;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPButton.SetIsToggleButton(const AValue: Boolean);
begin
  if AValue <> FIsToggleButton then
  begin
    FIsToggleButton := AValue;
    UpdateColors;
    Invalidate;
  end;
end;

procedure TUWPButton.SetIsToggled(const AValue: Boolean);
begin
  if AValue <> FIsToggled then
  begin
    FIsToggled := AValue;
    UpdateColors;
    Invalidate;
  end;
end;

procedure TUWPButton.SetTransparent(const AValue: Boolean);
begin
  if AValue <> FTransparent then
  begin
    FTransparent := AValue;
    UpdateColors;
    Invalidate;
  end;
end;

procedure TUWPButton.UpdateColorization(const IncludeChildren: Boolean);
begin
  UpdateColors;
  UpdateRects;
  Invalidate;
end;

procedure TUWPButton.UpdateColors;
var
  LCM: TUWPColorizationManager;
  LIsDark: Boolean;
  LAccentColor: TColor;
  LBackColor: TUWPStateColorSet;
  LBorderColor: TUWPStateColorSet;
begin
  LCM := SelectColorizationManager(Self);
  LIsDark := (LCM <> nil) and (LCM.Colorization = ucDark);
  LAccentColor := SelectAccentColor(LCM, $D77800);

  if not Enabled then
  begin
    if LIsDark then
      BackColor := $333333
    else
      BackColor := $CCCCCC;
    BorderColor := BackColor;
    TextColor := $666666;
  end
  else
  begin
    // Highlight
    if ((Highlight) or ((IsToggleButton) and (IsToggled)))
    and (ButtonState in [csNone, csHover])
    then
    begin
      BackColor := LAccentColor;
      if (ButtonState = csHover) or (AllowFocus and Focused) then
        BorderColor := BrightenColor(BackColor, -32)
      else
        BorderColor := BackColor;
    end
    // Transparent
    else if (ButtonState = csNone) and Transparent then
    begin
      ParentColor := True;
      BackColor := Color;
      BorderColor := Color;
    end
    // Default
    else
    begin
      LBackColor := SelectColorSet(LCM, CustomBackColor, BUTTON_BACK);
      LBorderColor := SelectColorSet(LCM, CustomBorderColor, BUTTON_BORDER);

      BackColor := LBackColor.GetColor(LCM, ButtonState, Focused);
      BorderColor := LBorderColor.GetColor(LCM, ButtonState, Focused);
    end;

    TextColor := GetTextColorFromBackground(BackColor);
  end;
end;

procedure TUWPButton.UpdateRects;
begin
  if (Images <> nil) and (ImageIndex >= 0) then
  begin
    ImgRect := Rect(0, 0, Height, Height);
    TextRect := Rect(Height, 0, Width, Height);
  end
  else
    TextRect := Rect(0, 0, Width, Height);
end;

procedure TUWPButton.WMKillFocus(var AMsg: TWMKillFocus);
begin
  if not Enabled then Exit;
  if AllowFocus then
  begin
    UpdateColors;
    Invalidate;
  end;
end;

procedure TUWPButton.WMLButtonDown(var AMsg: TWMLButtonDown);
begin
  if not Enabled then Exit;
  if AllowFocus then
    SetFocus;
  ButtonState := csPress;
  inherited;
end;

procedure TUWPButton.WMLButtonUp(var AMsg: TWMLButtonUp);
var
  LMousePos: TPoint;
begin
  if not Enabled then Exit;

  LMousePos := ScreenToClient(Mouse.CursorPos);
  if PtInRect(GetClientRect, LMousePos) then
  begin
    if IsToggleButton then
      FIsToggled := not FIsToggled;
  end;

  ButtonState := csHover;
  inherited;
end;

procedure TUWPButton.WMSetFocus(var AMsg: TWMSetFocus);
begin
  if not Enabled then Exit;
  if AllowFocus then
  begin
    SetFocus;
    UpdateColors;
    Invalidate;
  end;
end;

end.
