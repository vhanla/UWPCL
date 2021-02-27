unit UWP.Caption;

interface

uses
  Classes, Windows, Messages, Controls, ExtCtrls, Forms, Graphics, SysUtils, Types,
  UWP.Classes, UWP.ColorManager, UWP.Utils, UWP.Colors, UWP.Form, UWP.Graphics;

type
  TUWPCaptionButtonHover = (cbhNone, cbhClose, cbhMaximize, cbhMinimize);

  TUWPCaption = class(TPanel, IUWPControl)
  private
    var BackColor: TColor;
    var TextColor: TColor;
    var CloseRect, ResizeRect, MinRect, HelpRect: TRect;
    FButtonWidth: Integer;
    FButtonHovered: TUWPCaptionButtonHover;

    FCustomBackColor: TUWPColorizationColorSet;

    FCollapsed: Boolean;
    FDragToMove: Boolean;
    FSystemMenuEnabled: Boolean;


    // Internal
    procedure UpdateColors;

    // setters
    procedure SetCollapsed(const AValue: Boolean);

    // events to handle children
    procedure CustomBackColor_OnChange(Sender: TObject);

    // messages
    procedure WM_LButtonDblClk(var Msg: TWMLButtonDblClk); message WM_LBUTTONDBLCLK;
    procedure WM_LButtonDown(var Msg: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure WM_RButtonUp(var Msg: TMessage); message WM_RBUTTONUP;
    procedure WM_MouseMove(var Msg: TWMMouse); message WM_MOUSEMOVE;
    procedure WM_NCHitTest(var Msg: TWMNCHitTest); message WM_NCHITTEST;
    procedure CM_MouseEnter(var Msg: TMessage); message CM_MOUSEENTER;
    procedure CM_MouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Interface
    function IsContainer: Boolean;
    procedure UpdateColorization(const IncludeChildren: Boolean);
  published
    property CustomBackColor: TUWPColorizationColorSet read FCustomBackColor write FCustomBackColor;

    property Collapsed: Boolean read FCollapsed write SetCollapsed default False;
    property DragToMove: Boolean read FDragToMove write FDragToMove default True;
    property SystemMenuEnabled: Boolean read FSystemMenuEnabled write FSystemMenuEnabled default True;

    // modify default values
    property Align default alTop;
    property Alignment default taLeftJustify;
    property BevelOuter default bvNone;
    property Height default 32;
    property ParentBackground default False;
  end;

implementation

uses
  UWP.FontIcons, UWP.SystemSettings;
{ TUPCaption }

procedure TUWPCaption.CM_MouseEnter(var Msg: TMessage);
var
  LParentForm: TCustomForm;
begin
  inherited;
  LParentForm := GetParentForm(Self, True);
  if (LParentForm is TUWPForm) and (TUWPForm(LParentForm).FullScreen) then
    Collapsed := False;
end;

procedure TUWPCaption.CM_MouseLeave(var Msg: TMessage);
var
  LParentForm: TCustomForm;
begin
  inherited;

//  FButtonHovered := cbhNone;
  LParentForm := GetParentForm(Self, True);
  if (LParentForm is TUWPForm) and (TUWPForm(LParentForm).FullScreen) then
    if not PtInRect(GetClientRect, ScreenToClient(Mouse.CursorPos)) then
      Collapsed := True;
end;

constructor TUWPCaption.Create(AOwner: TComponent);
begin
  inherited;
  BackColor := $F2F2F2;
  TextColor := GetTextColorFromBackground(BackColor);

  FCollapsed := False;
  FDragToMove := True;
  FSystemMenuEnabled := True;

  FCustomBackColor := TUWPColorizationColorSet.Create;
  FCustomBackColor.OnChange := CustomBackColor_OnChange;
  FCustomBackColor.Assign(CAPTIONBAR_BACK);

  Align := alTop;
  Alignment := taLeftJustify;
  Caption := '   Caption Bar';
  BevelOuter := bvNone;
  //Height := GetSystemMetrics(SM_CYCAPTION);
  Height := 32;
  ParentBackground := False;
  FButtonWidth := 45;

  CloseRect := Rect(0, 0, Height, Height);
  ResizeRect := Rect(0, 0, Height, Height);
  MinRect := Rect(0, 0, Height, Height);
  HelpRect := Rect(0, 0, Height, Height);

  Color := $F2F2F2;
end;


procedure TUWPCaption.CustomBackColor_OnChange(Sender: TObject);
begin
  UpdateColorization(True);
end;

destructor TUWPCaption.Destroy;
begin
  FCustomBackColor.Free;
  inherited;
end;

function TUWPCaption.IsContainer: Boolean;
begin
  Result := True;
end;

procedure TUWPCaption.Paint;
var
  LParentForm: TCustomForm;
begin
  //inherited;
  with Canvas do begin
    Brush.Handle := CreateSolidBrushWithAlpha(BackColor, 255);
    FillRect(Rect(0, 0, Width, Height));

    if ShowCaption then
    begin
      Font.Assign(Self.Font);
      Font.Color := TextColor;
      DrawTextRect(Self.Canvas, Alignment, VerticalAlignment,
        Rect(0, 0, Width, Height), Caption, False);

      LParentForm := GetParentForm(Self, True);

      if biSystemMenu in TUWPForm(LParentForm).BorderIcons then
      begin
        Font.Name := 'Segoe MDL2 Assets';
        Font.Size := 10;
        Font.Color := clGrayText;

        Brush.Handle := CreateSolidBrushWithAlpha(BackColor, 255);
        if FButtonHovered = cbhClose then
        begin
          Brush.Handle := CreateSolidBrushWithAlpha($2311E8, 255);
          Font.Color := clWhite;
        end;

        FillRect(Rect(Width - FButtonWidth, 0, Width, Height));

        DrawTextRect(Canvas, taCenter, taVerticalCenter, Rect(Width - FButtonWidth, 0, Width, Height), UF_CLOSE, False);

        if (biMaximize in TUWPForm(LParentForm).BorderIcons) then
        begin
          Font.Color := clGray;
          if TUWPForm(LParentForm).WindowState = wsMaximized then
            DrawTextRect(Canvas, taCenter, taVerticalCenter, Rect(Width - 2 * FButtonWidth, 0, Width - FButtonWidth, Height), UF_RESTORE, False)
          else
            DrawTextRect(Canvas, taCenter, taVerticalCenter, Rect(Width - 2 * FButtonWidth, 0, Width - FButtonWidth, Height), UF_MAXIMIZE, False);
        end;

        if (biMinimize in TUWPForm(LParentForm).BorderIcons) then
        begin
          Font.Color := clGray;
          DrawTextRect(Canvas, taCenter, taVerticalCenter, Rect(Width - 3 * FButtonWidth, 0, Width - 2 * FButtonWidth, Height), UF_MINIMIZE, False);
        end;
      end
      else
      begin
        // do not draw
      end;

    end;
  end;
end;

procedure TUWPCaption.SetCollapsed(const AValue: Boolean);
begin
  if AValue <> FCollapsed then
  begin
    FCollapsed := AValue;

    if csDesigning in ComponentState then
      Exit;

    ShowCaption := not AValue;
    if AValue then
    begin
      Padding.Bottom := 1;
    end
    else
    begin
      Padding.Bottom := 0;
    end;

  end;
end;

procedure TUWPCaption.UpdateColorization(const IncludeChildren: Boolean);
var
  I: Integer;
begin
  UpdateColors;
end;

procedure TUWPCaption.UpdateColors;
var
  LCM: TUWPColorizationManager;
  LBackColor: TUWPColorizationColorSet;
begin
  LCM := SelectColorizationManager(Self);

  // Update back color
  LBackColor := SelectColorSet(LCM, CustomBackColor, CAPTIONBAR_BACK);
  if IsColorOnBorderEnabled then
    BackColor := GetAccentColor
  else
    BackColor := LBackColor.GetColor(LCM);

  // Update text color depending on back color
  TextColor := GetTextColorFromBackground(BackColor);

  // Update color for container (let children using ParentColor);
  Color := BackColor;
end;

procedure TUWPCaption.WM_LButtonDblClk(var Msg: TWMLButtonDblClk);
var
  LParentForm: TCustomForm;
begin
  inherited;

  LParentForm := GetParentForm(Self, True);
  if LParentForm is TForm then
    if biMaximize in (LParentForm as TForm).BorderIcons then
    begin
      if LParentForm is TUWPForm then
        if TUWPForm(LParentForm).FullScreen then
          Exit;
      if LParentForm.WindowState = wsMaximized then
        LParentForm.WindowState := wsNormal
      else if LParentForm.WindowState = wsNormal then
        LParentForm.WindowState := wsMaximized;
    end;

end;

procedure TUWPCaption.WM_LButtonDown(var Msg: TWMLButtonDown);
begin
  inherited;
  if DragToMove then
  begin
    ReleaseCapture;
    Parent.Perform(WM_SYSCOMMAND, $F012, 0);
  end;
end;

procedure TUWPCaption.WM_MouseMove(var Msg: TWMMouse);
var
  LPrevHoveredStatus: TUWPCaptionButtonHover;
begin
  inherited;

  LPrevHoveredStatus := FButtonHovered;

  // Hover on Close
  if (Msg.XPos > Width - FButtonWidth)
  and (Msg.XPos < Width)
  then
  begin
      FButtonHovered := cbhClose;
      if LPrevHoveredStatus <> FButtonHovered then
        Invalidate;
  end
  // Hover on Maximize
  else if (Msg.XPos > Width - 2 * FButtonWidth)
  and (Msg.XPos < Width - FButtonWidth)
  then
  begin
      FButtonHovered := cbhMaximize;
      if LPrevHoveredStatus <> FButtonHovered then
        Invalidate;
  end
  // Hover on Minimize
  else if (Msg.XPos > Width - 3 * FButtonWidth)
  and (Msg.XPos < Width - 2 * FButtonWidth)
  then
  begin
      FButtonHovered := cbhMinimize;
      if LPrevHoveredStatus <> FButtonHovered then
        Invalidate;
  end
  // Hover outside them
  else
    begin
      FButtonHovered := cbhNone;
      if LPrevHoveredStatus <> FButtonHovered then
        Invalidate;
    end;
end;

procedure TUWPCaption.WM_NCHitTest(var Msg: TWMNCHitTest);
var
  P: TPoint;
  LParentForm: TCustomForm;
begin
  inherited;

  LParentForm := GetParentForm(Self, True);
  if (LParentForm.WindowState = wsNormal) and (Align = alTop) then
  begin
    P := Point(Msg.Pos.x, Msg.Pos.y);
    P := ScreenToClient(P);
    if P.Y < 5 then
      Msg.Result := HTTRANSPARENT; // send event to parent
  end;
end;

procedure TUWPCaption.WM_RButtonUp(var Msg: TMessage);
const
  WM_SYSMENU = 787;
var
  P: TPoint;
begin
  inherited;
  if SystemMenuEnabled then
  begin
    P.X := Msg.LParamLo;
    P.Y := Msg.LParamHi;
    P := ClientToScreen(P);
    Msg.LParamLo := P.X;
    Msg.LParamHi := P.Y;
    PostMessage(Parent.Handle, WM_SYSMENU, 0, Msg.LParam);
  end;
end;

end.
