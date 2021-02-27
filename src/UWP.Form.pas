{
  This Unit/Component extends VCL Form to use Direct2D alpha drawing over glass frame.
}
unit UWP.Form;

interface

uses
  SysUtils, Classes, Windows, VCL.Forms, VCL.Controls, VCL.Graphics, VCL.Dialogs, Messages,
  UWP.Classes, UWP.ColorManager, UWP.Colors, UWP.Utils, UWP.SystemSettings,
  VCL.Direct2D, Winapi.D2D1, UWP.FormShadow;

type
  TUWPForm = class(TForm, IUWPControl)
  private
    const
      FORM_BORDER_ACTIVE_LIGHT = $707070;
      FORM_BORDER_ACTIVE_DARK = $6D6B68;
      FORM_BORDER_INACTIVE_LIGHT = $AAAAAA;
      FORM_BORDER_INACTIVE_DARK =$A5A29A;
    var
      BorderColor: TColor;

    FColorizationManager: TUWPColorizationManager;
    FCustomBackColor: TUWPColorizationColorSet;

    FIsActive: Boolean;
    FPPI: Integer;
    FFitDesktop: Boolean;

    FShadow: TfrmShadow;
    FShadowEnabled: Boolean;
    FShadowOnBorderless: Boolean;
    FFullScreen: Boolean;
    FFluentEnabled: Boolean;
    F2DCanvas: TDirect2DCanvas;
    FD2DFactory: ID2D1Factory;
    FDeviceResourcesValid: Boolean;

    function IsResizable: Boolean;
    function HasBorder: Boolean;
    function CanDrawBorder: Boolean;
    procedure UpdateBorderColor;
    procedure DoDrawBorder;

    procedure ColorizationManager_OnChange(Sender: TObject);
    procedure CustomBackColor_OnChange(Sender: TObject);

    function GetNCBorderSize: Integer;
    procedure WMSysCommand(var AMsg: TWMSysCommand); message WM_SYSCOMMAND;
    procedure WMActivate(var AMsg: TWMActivate); message WM_ACTIVATE;
    procedure WMDPIChanged(var AMsg: TWMDpi); message WM_DPICHANGED;
    procedure WMDWMColorizationColorChanged(var AMsg: TMessage); message WM_DWMCOLORIZATIONCOLORCHANGED;
    procedure WM_NCCalcSize(var Msg: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WM_NCHitTest(var Msg: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMMove(var Msg: TWMMove); message WM_MOVE;
    procedure WMSize(var Msg: TWMSize); message WM_SIZE;

    procedure SetFullScreen(const AValue: Boolean);
    procedure SetFluent(const AValue: Boolean);
  protected
    //procedure CreateWnd; override;
    constructor Create(AOwner: TComponent); override;
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
    procedure InitForm;
    procedure WndProc(var Msg: TMessage); override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Paint; override;
    procedure Resize; override;
    destructor Destroy; override;
    procedure OnFormShow(Sender: TObject);
    procedure OnFormActivate(Sender: TObject);
    procedure OnFormDeactivate(Sender: TObject);

  public
    function IsContainer: Boolean;
    procedure UpdateColorization(const IncludeChildren: Boolean);

    procedure ScaleForPPI(NewPPI: Integer); override;
  published
    property ColorizationManager: TUWPColorizationManager read FColorizationManager write FColorizationManager;
    property CustomBackColor: TUWPColorizationColorSet read FCustomBackColor write FCustomBackColor;

    property IsActive: Boolean read FIsActive default True;
    property PPI: Integer read FPPI write FPPI default 96;
    property FitDesktop: Boolean read FFitDesktop write FFitDesktop default True;

    property ShadowOnBorderless: Boolean read FShadowOnBorderless write FShadowOnBorderless;
    property FullScreen: Boolean read FFullScreen write SetFullScreen default False;
    property FluentEnabled: Boolean read FFluentEnabled write SetFluent default False;

    property Padding stored False;
  end;

implementation

uses
  UWP.ToolTip;

{ TUWPForm }

function TUWPForm.CanDrawBorder: Boolean;
begin
  Result := (WindowState = wsNormal) and HasBorder;
end;

procedure TUWPForm.ColorizationManager_OnChange(Sender: TObject);
begin
  UpdateColorization(True);
end;

constructor TUWPForm.Create(AOwner: TComponent);
begin
  inherited;
  InitForm;
end;

constructor TUWPForm.CreateNew(AOwner: TComponent; Dummy: Integer);
begin
  inherited;
  InitForm;
end;

procedure TUWPForm.CreateParams(var Params: TCreateParams);
begin
  inherited;

  Params.Style := Params.Style or 200000 or WS_OVERLAPPEDWINDOW and not WS_SYSMENU or WS_THICKFRAME;

end;

//procedure TUWPForm.CreateWnd;
//begin
//  inherited;
//
//  FColorizationManager := TUWPColorizationManager.Create;
//  FColorizationManager.OnChange := ColorizationManager_OnChange;
//  FCustomBackColor := TUWPColorizationColorSet.Create;
//  FCustomBackColor.OnChange := CustomBackColor_OnChange;
//  FCustomBackColor.Assign(FORM_BACK);
//
//  Font.Name := FORM_FONT_NAME;
//  Font.Size := FORM_FONT_SIZE;
//
//  FIsActive := True;
//  FFitDesktop := True;
//  FFullScreen := False;
//
//  FPPI := Screen.MonitorFromWindow(Handle).PixelsPerInch;
//
////  FShadow := TfrmShadow.Create(Self);
//  OnShow := OnFormShow;
////  Application.OnActivate := OnFormActivate;
////  Application.OnDeactivate := OnFormDeactivate;
//
//  F2DCanvas := TDirect2DCanvas.Create(Handle);
//  if FFluentEnabled then
//    SetFluent(True);
//  FD2DFactory := VCL.Direct2D.D2DFactory;
//
//  FColorizationManager.UpdateColorization;
//end;

procedure TUWPForm.CustomBackColor_OnChange(Sender: TObject);
begin
  UpdateColorization(True);
end;

destructor TUWPForm.Destroy;
begin
  FreeAndNil(F2DCanvas);
  FCustomBackColor.Free;
  FColorizationManager.Free;
//  FShadow.Free;
  inherited;
end;

procedure TUWPForm.DoDrawBorder;
begin
  Canvas.Brush.Handle := CreateSolidBrushWithAlpha(Color, 255);
  Canvas.Pen.Color := CreateSolidBrushWithAlpha(BorderColor);
  if FluentEnabled then
  begin
    Canvas.MoveTo(0, 1);
    Canvas.LineTo(Width, 1);
  end
  else
  begin
    Canvas.MoveTo(0, 0);
    Canvas.LineTo(Width, 0);
  end;
end;

function TUWPForm.GetNCBorderSize: Integer;
begin
  case BorderStyle of
    bsSingle:
      Result := GetSystemMetrics(SM_CYFIXEDFRAME);

    bsDialog, bsToolWindow:
      Result := GetSystemMetrics(SM_CYDLGFRAME);

    bsSizeable, bsSizeToolWin:
      Result := GetSystemMetrics(SM_CYSIZEFRAME) +
                GetSystemMetrics(SM_CXPADDEDBORDER);
    else
      Result := 0;
  end;
end;

function TUWPForm.HasBorder: Boolean;
begin
  Result := BorderStyle in [bsDialog, bsSingle, bsSizeable];
end;

procedure TUWPForm.InitForm;
begin
  FColorizationManager := TUWPColorizationManager.Create;
  FColorizationManager.OnChange := ColorizationManager_OnChange;
  FCustomBackColor := TUWPColorizationColorSet.Create;
  FCustomBackColor.OnChange := CustomBackColor_OnChange;
  FCustomBackColor.Assign(FORM_BACK);

  Font.Name := FORM_FONT_NAME;
  Font.Size := FORM_FONT_SIZE;

  FIsActive := True;
  FFitDesktop := True;
  FFullScreen := False;

  FPPI := Screen.MonitorFromWindow(Handle).PixelsPerInch;

//  FShadow := TfrmShadow.Create(Self);
  OnShow := OnFormShow;
//  Application.OnActivate := OnFormActivate;
//  Application.OnDeactivate := OnFormDeactivate;

  if FFluentEnabled then
    SetFluent(True);

  F2DCanvas := TDirect2DCanvas.Create(Handle);
  FD2DFactory := VCL.Direct2D.D2DFactory;

  FColorizationManager.UpdateColorization;
end;

function TUWPForm.IsContainer: Boolean;
begin
  Result := True;
end;

function TUWPForm.IsResizable: Boolean;
begin
  Result := BorderStyle in [bsSizeable, bsSizeToolWin];
end;

procedure TUWPForm.OnFormActivate(Sender: TObject);
begin
  if Assigned(FShadow) then
    FShadow.ActivateShadow := True;
end;

procedure TUWPForm.OnFormDeactivate(Sender: TObject);
begin
  if Assigned(FShadow) then
    FShadow.ActivateShadow := False;
end;

procedure TUWPForm.OnFormShow(Sender: TObject);
begin
  if not FShadowOnBorderless then Exit;
  FShadow.ClientWidth := ClientWidth + FShadow.FMargins.Left + FShadow.FMargins.Right;
  FShadow.ClientHeight := ClientHeight + FShadow.FMargins.Top + FShadow.FMargins.Bottom;
  FShadow.Left := Self.Left - FShadow.FMargins.Left;
  FShadow.Top := Self.Top - FShadow.FMargins.Top;
  ShowWindow(FShadow.Handle, SW_SHOWNA);
end;

procedure TUWPForm.Paint;
begin
  inherited;
//  TDirect2DCanvas.Create(Handle);
  F2DCanvas.BeginDraw;
  try
    // Erase background
    F2DCanvas.RenderTarget.Clear(D2D1ColorF(clDkGray, 255));
  finally
    F2DCanvas.EndDraw;
  end;

  if CanDrawBorder then
  begin
//  Canvas.Brush.Handle := CreateSolidBrushWithAlpha(Color, 200);
//  Canvas.FillRect(Rect(0, 0, Width, Height));
    DoDrawBorder;
  end;
end;

procedure TUWPForm.Resize;
var
  LCurrentMonitor: TMonitor;
  LSpace: Integer;
begin
  inherited;

  //F2DCanvas := TDirect2DCanvas.Create(Handle);
  //Invalidate;

  if CanDrawBorder then
  begin
    if Padding.Top = 0 then
      Padding.Top := 1;
  end
  else if (Padding.Top = 1) and (WindowState = wsMaximized) then
    Padding.Top := 0;

  LCurrentMonitor := Screen.MonitorFromWindow(Handle);

  if FullScreen and (WindowState = wsMaximized) then
  begin
    Top := LCurrentMonitor.Top;
    Left := LCurrentMonitor.Left;
    Width := LCurrentMonitor.Width;
    Height := LCurrentMonitor.Height;
  end;

  // fit desktop size on maximize
  if (WindowState = wsMaximized) and
    FitDesktop and
    (BorderStyle in [bsDialog, bsSizeToolWin, bsToolWindow]) then
  begin
    LSpace := GetNCBorderSize;
    Top := - LSpace;
    Left := - LSpace;
    Width := LCurrentMonitor.WorkareaRect.Width + 2 * LSpace;
    Height := LCurrentMonitor.WorkareaRect.Height + 2 * LSpace;
  end;

end;

procedure TUWPForm.ScaleForPPI(NewPPI: Integer);
begin
  PPI := NewPPI;
  inherited;
end;

procedure TUWPForm.SetFluent(const AValue: Boolean);
begin
  if AValue then
  begin
    EnableBlur(Handle, ACCENT_ENABLE_ACRYLICBLURBEHIND);
    BorderStyle := bsNone;
    SetWindowLong(Handle, GWL_STYLE, GetWindowLong(Handle, GWL_STYLE) or WS_MINIMIZEBOX or WS_MAXIMIZEBOX or WS_SYSMENU {or WS_OVERLAPPEDWINDOW});
    //#TODO: fix incorrect client size on start up for fluent mode
    SetWindowPos(Handle, 0, Left, Top, Width, Height, SWP_NOMOVE or SWP_FRAMECHANGED or SWP_DRAWFRAME or SWP_HIDEWINDOW);
    BorderStyle := bsSizeable;                                                                                           //
    SetWindowPos(Handle, 0, Left, Top, Width, Height, SWP_NOMOVE or SWP_FRAMECHANGED or SWP_DRAWFRAME or SWP_SHOWWINDOW);
    Padding.Left := 0;
    Padding.Right := 0;
    Padding.Bottom := 0;
  end
  else
    EnableBlur(Handle, ACCENT_ENABLE_NORMAL);
  FFluentEnabled := AValue;
end;

procedure TUWPForm.SetFullScreen(const AValue: Boolean);
begin
  if AValue <> FFullScreen then
  begin
    FFullScreen := AValue;

    LockWindowUpdate(Handle);

    if AValue then
    begin
      BorderStyle := bsNone;
      if WindowState = wsMaximized then
        WindowState := wsNormal;
      WindowState := wsMaximized;
      //#TODO: Maybe go always on top as optional
    end
    else
    begin
      BorderStyle := bsSizeable;
      WindowState := wsNormal;

    end;

    LockWindowUpdate(0);
  end;
end;

procedure TUWPForm.UpdateBorderColor;
var
  LCM: TUWPColorizationManager;
begin
  LCM := ColorizationManager;

  if LCM = nil then
    BorderColor := FORM_BORDER_ACTIVE_LIGHT
  else if IsActive then
  begin
    if ColorizationManager.ColoredBorder then
      BorderColor := GetAccentColor
    else if ColorizationManager.Colorization = ucLight then
      BorderColor := FORM_BORDER_ACTIVE_LIGHT
    else
      BorderColor := FORM_BORDER_ACTIVE_DARK;
  end
  else //window is inactive
  begin
    if ColorizationManager.Colorization = ucLight then
      BorderColor := FORM_BORDER_INACTIVE_LIGHT
    else
      BorderColor := FORM_BORDER_INACTIVE_DARK;
  end;



end;

procedure TUWPForm.UpdateColorization(const IncludeChildren: Boolean);
var
  I: Integer;
  LCM: TUWPColorizationManager;
  LBackColor: TUWPColorizationColorSet;
begin
  LCM := ColorizationManager;

  LBackColor := SelectColorSet(LCM, CustomBackColor, FORM_BACK);
  Color := LBackColor.GetColor(LCM);

  if LCM = nil then
    HintWindowClass := THintWindow
  else if LCM.Colorization = ucLight then
    HintWindowClass := TUWPLightTooltip
  else
    HintWindowClass := TUWPDarkTooltip;

  // update children
  if IsContainer and IncludeChildren then
  begin
    LockWindowUpdate(Handle);
    for I := 0 to ControlCount - 1 do
      if Supports(Controls[I], IUWPControl) then
        (Controls[I] as IUWPControl).UpdateColorization(IncludeChildren);
    LockWindowUpdate(0)
  end;
end;

procedure TUWPForm.WMActivate(var AMsg: TWMActivate);
begin
  inherited;
  FIsActive := AMsg.Active <> WA_INACTIVE;

  if CanDrawBorder then
  begin
    UpdateBorderColor;
    DoDrawBorder;
  end;
end;

procedure TUWPForm.WMDPIChanged(var AMsg: TWMDpi);
begin
  inherited;
  ScaleForPPI(AMsg.XDpi);
end;

procedure TUWPForm.WMDWMColorizationColorChanged(var AMsg: TMessage);
begin
  inherited;
  if ColorizationManager <> nil then
    ColorizationManager.UpdateColorization;
end;

procedure TUWPForm.WMMove(var Msg: TWMMove);
begin
  inherited;

  if Assigned(FShadow) then
  begin
    FShadow.Left := Msg.XPos - FShadow.FMargins.Left;
    FShadow.Top := Msg.YPos - FShadow.FMargins.Top;
  end;
end;

procedure TUWPForm.WMSize(var Msg: TWMSize);
begin
  inherited;

  if Assigned(FShadow) then
  begin
    FShadow.ClientWidth := Width + FShadow.FMargins.Left + FShadow.FMargins.Right;
    FShadow.ClientHeight := Height + FShadow.FMargins.Top + FShadow.FMargins.Bottom;
  end;
end;

procedure TUWPForm.WMSysCommand(var AMsg: TWMSysCommand);
begin
  if FullScreen then
    // prevent move and restore
    case AMsg.CmdType and $FFF0 of
      SC_MOVE, SC_RESTORE:
        Exit;
    end;

  inherited;
end;

procedure TUWPForm.WM_NCCalcSize(var Msg: TWMNCCalcSize);
var
  LCaptionBarHeight: Integer;
begin
  inherited;
//  if not FluentEnabled then
  if BorderStyle = bsNone then Exit;

  LCaptionBarHeight := GetSystemMetrics(SM_CYCAPTION);

  if WindowState = wsNormal then
    Inc(LCaptionBarHeight, GetNCBorderSize);

  Dec(Msg.CalcSize_Params.rgrc[0].Top, LCaptionBarHeight);
  if FluentEnabled then
  begin
    Dec(Msg.CalcSize_Params.rgrc[0].Top);
    Dec(Msg.CalcSize_Params.rgrc[0].Left, GetNCBorderSize);
    Inc(Msg.CalcSize_Params.rgrc[0].Right, GetNCBorderSize);
    Inc(Msg.CalcSize_Params.rgrc[0].Bottom, GetNCBorderSize);
  end;
end;

procedure TUWPForm.WM_NCHitTest(var Msg: TWMNCHitTest);
var
  LResizePadding: Integer;
  LIsResizable: Boolean;
begin
  inherited;
  LResizePadding := GetNCBorderSize;

  LIsResizable := (WindowState = wsNormal)
    and (BorderStyle in [bsSizeable, bsSizeToolWin]);

  //if LIsResizable and (Msg.YPos - BoundsRect.Top <= LResizePadding div 2) then
  if LIsResizable and (Msg.YPos - BoundsRect.Top <= LResizePadding) then
  begin
    if Msg.XPos - BoundsRect.Left <= 2 * LResizePadding then
      Msg.Result := HTTOPLEFT
    else if BoundsRect.Right - Msg.XPos <= 2 * LResizePadding then
      Msg.Result := HTTOPRIGHT
    else
      Msg.Result := HTTOP;
  end;
end;

procedure TUWPForm.WndProc(var Msg: TMessage);
begin
  if FFluentEnabled then
  begin
    case Msg.Msg of
      //WM_NCCALCSIZE: Msg.Msg := WM_NULL;
      WM_ENTERSIZEMOVE:
        EnableBlur(Handle, ACCENT_ENABLE_BLURBEHIND);

      WM_EXITSIZEMOVE:
        EnableBlur(Handle, ACCENT_ENABLE_ACRYLICBLURBEHIND);
    end;
  end;

  inherited WndProc(Msg);
end;

end.
