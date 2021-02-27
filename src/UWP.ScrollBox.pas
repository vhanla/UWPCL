unit UWP.ScrollBox;

interface

uses
  Classes, Types, SysUtils, Windows, Messages, Graphics, FlatSB,
  Controls, StdCtrls, Forms, Dialogs, ExtCtrls,
  UWP.IntAnimation, UWP.Classes, UWP.Utils, UWP.ColorManager, UWP.Colors;

type
  TUWPScrollBarStyle = (sbsMini, sbsFull, sbsNo);

  TUWPMiniScrollBar = class(TCustomPanel)
  private
    procedure WMNCHitTest(var AMsg: TWMNCHitTest); message WM_NCHITTEST;

  public
    constructor Create(AOwner: TComponent); override;

  published
    property Visible default False;
  end;

  TUWPScrollBox = class(TScrollBox, IUWPControl)
  private
    var MouseLeave: Boolean;
    var MiniSB: TUWPMiniScrollBar;
    var MiniSBThickness: Byte;
    var MiniSBMargin: Byte;
    var MiniSBColor: TColor;

    FAniSet: TIntAniSet;
    FCustomBackColor: TUWPColorizationColorSet;

    FScrollCount: Integer;
    FScrollOrientation: TUWPOrientation;
    FScrollBarStyle: TUWPScrollBarStyle;
    FLengthPerStep: Integer;
    FMaxScrollCount: Integer;

    // Events for children
    procedure CustomBackColor_OnChange(Sender: TObject);

    // Message handling
    procedure WMSize(var AMsg: TWMSize); message WM_SIZE;
    procedure CMMouseWheel(var AMsg: TCMMouseWheel); message CM_MOUSEWHEEL;
    procedure CMMouseEnter(var AMsg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var AMsg: TMessage); message CM_MOUSELEAVE;

  protected
    procedure ChangeScale(M, D: Integer; DpiChanged: Boolean); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Interface
    function IsContainer: Boolean;
    procedure UpdateColorization(const IncludeChildren: Boolean);

    // Utils
    procedure SetOldSBVisible(AVisible: Boolean);
    procedure SetMiniSBVisible(AVisible: Boolean);
    procedure UpdateMiniSB;
    procedure ClearBox;

  published
    property AniSet: TIntAniSet read FAniSet write FAniSet;
    property CustomBackColor: TUWPColorizationColorSet read FCustomBackColor write FCustomBackColor;

    property ScrollCount: Integer read FScrollCount;
    property ScrollOrientation: TUWPOrientation read FScrollOrientation write FScrollOrientation default oVertical;
    property ScrollBarStyle: TUWPScrollBarStyle read FScrollBarStyle write FScrollBarStyle default sbsMini;
    property LengthPerStep: Integer read FLengthPerStep write FLengthPerStep default 2;
    property MaxScrollCount: Integer read FMaxScrollCount write FMaxScrollCount default 0;

    // Modify default props
    property BorderStyle default bsNone;
  end;

implementation

{ TUWPMiniScrollBar }

constructor TUWPMiniScrollBar.Create(AOwner: TComponent);
begin
  inherited;

  BevelOuter := bvNone;
  FullRepaint := False;
  DoubleBuffered := True;
  Visible := False;

  StyleElements := [];
end;

procedure TUWPMiniScrollBar.WMNCHitTest(var AMsg: TWMNCHitTest);
begin
  AMsg.Result := HTTRANSPARENT;
end;

{ TUWPScrollBox }

procedure TUWPScrollBox.ChangeScale(M, D: Integer; DpiChanged: Boolean);
begin
  inherited;
  MiniSBThickness := MulDiv(MiniSBThickness, M, D);
  MiniSBMargin := MulDiv(MiniSBMargin, M, D);
  FLengthPerStep := MulDiv(FLengthPerStep, M, D);
end;

procedure TUWPScrollBox.ClearBox;
var
  I: Integer;
begin
  I := 0;
  while ControlCount > I do
    if Controls[I] = MiniSB then
      Inc(I)
    else
      Controls[I].Free;
end;

procedure TUWPScrollBox.CMMouseEnter(var AMsg: TMessage);
begin
  inherited;

  if Win32MajorVersion < 10 then
    SetFocus;

  if MouseLeave and (PtInRect(GetClientRect, ScreenToClient(Mouse.CursorPos))) then
  begin
    if FScrollBarStyle <> sbsFull then
      SetOldSBVisible(False);

    if FScrollBarStyle = sbsMini then
      SetMiniSBVisible(True);
  end;
end;

procedure TUWPScrollBox.CMMouseLeave(var AMsg: TMessage);
begin
  inherited;

  MouseLeave := True;
  if ScrollBarStyle = sbsMini then
    if not PtInRect(GetClientRect, ScreenToClient(Mouse.CursorPos)) then
    begin
      MouseLeave := True;
      SetMiniSBVisible(False);
    end;
end;

procedure TUWPScrollBox.CMMouseWheel(var AMsg: TCMMouseWheel);
var
  LSB: TControlScrollBar;
  LAni: TIntAni;
  LSign: Integer;
begin
  inherited;

  if not PtInRect(GetClientRect, ScreenToClient(Mouse.CursorPos)) then
    Exit;

  if ScrollOrientation = oVertical then
    LSB := VertScrollBar
  else
    LSB := HorzScrollBar;

  // Scroll by touchpad
  if (Abs(AMsg.WheelDelta) < 100) or (csDesigning in ComponentState) then
  begin
    if csDesigning in ComponentState then
      AMsg.WheelDelta := 10 * AMsg.WheelDelta div Abs(AMsg.WheelDelta);

    DisableAlign;
    LSB.Position := LSB.Position - AMsg.WheelDelta;
    if FScrollBarStyle = sbsMini then
      UpdateMiniSB;
    EnableAlign;
  end
  // Scrolling with mouse
  else
  begin
    if FScrollCount >= MaxScrollCount then Exit;

    if FScrollCount = 0 then
    begin
      DisableAlign;
      Mouse.Capture := Handle;
    end;

    Inc(FScrollCount);
    LSign := AMsg.WheelDelta div Abs(AMsg.WheelDelta);

    LAni := TIntAni.Create(1, +LengthPerStep, nil, nil);
    LAni.AniSet.Assign(Self.AniSet);

    if FScrollBarStyle = sbsMini then
    begin
      LAni.OnSync :=
        procedure (V: Integer)
        begin
          LSB.Position := LSB.Position - V * LSign;
          UpdateMiniSB;
        end;
    end
    else
    begin
      LAni.OnSync :=
        procedure (V: Integer)
        begin
          LSB.Position := LSB.Position - V * LSign;
        end;
    end;

    LAni.OnDone :=
      procedure
      begin
        if FScrollBarStyle <> sbsFull then
          SetOldSBVisible(False);
        Dec(FScrollCount);
        if FScrollCount = 0 then
        begin
          EnableAlign;
          Mouse.Capture := 0;
        end;
      end;

    LAni.Start;
  end;
end;

constructor TUWPScrollBox.Create(AOwner: TComponent);
begin
  inherited;

  MouseLeave := True;
  MiniSBThickness := 2;
  MiniSBMargin := 3;
  MiniSBColor := $7A7A7A; // for both coloring modes (dark/light)

  MiniSB := TUWPMiniScrollBar.Create(Self);
  MiniSB.Color := MiniSBColor;
  MiniSB.Parent := Self;
  MiniSB.SetSubComponent(True);
  MiniSB.Visible := False;
  MiniSB.Width := 0;

  FScrollCount := 0;
  FScrollOrientation := oVertical;
  FScrollBarStyle := sbsMini;
  FLengthPerStep := 2;
  FMaxScrollCount := 8;

  FAniSet := TIntAniSet.Create;
  FAniSet.QuickAssign(akOut, afkQuintic, 0, 120, 11);

  FCustomBackColor := TUWPColorizationColorSet.Create;
  FCustomBackColor.OnChange := CustomBackColor_OnChange;
  FCustomBackColor.Assign(SCROLLBOX_BACK);

  // Modify default props
  BorderStyle := bsNone;
  VertScrollBar.Tracking := True;
  HorzScrollBar.Tracking := True;

end;

procedure TUWPScrollBox.CustomBackColor_OnChange(Sender: TObject);
begin
  UpdateColorization(True);
end;

destructor TUWPScrollBox.Destroy;
begin
  MiniSB.Free;
  FCustomBackColor.Free;
  FAniSet.Free;
  inherited;
end;

function TUWPScrollBox.IsContainer: Boolean;
begin
  Result := True;
end;

procedure TUWPScrollBox.SetMiniSBVisible(AVisible: Boolean);
begin
  MiniSB.Visible := AVisible;
  if AVisible then
  begin
    UpdateMiniSB;
    MiniSB.BringToFront;
  end;
end;

procedure TUWPScrollBox.SetOldSBVisible(AVisible: Boolean);
begin
  if not (csDesigning in ComponentState) then
    FlatSB_ShowScrollBar(Handle, SB_BOTH, AVisible);
end;

procedure TUWPScrollBox.UpdateColorization(const IncludeChildren: Boolean);
var
  I: Integer;
  LCM: TUWPColorizationManager;
  LBackColor: TUWPColorizationColorSet;
begin
  LCM := SelectColorizationManager(Self);
  LBackColor := SelectColorSet(LCM, CustomBackColor, SCROLLBOX_BACK);

  // Update background color
  Color := LBackColor.GetColor(LCM);

  // Update childre too
  if IsContainer and IncludeChildren then
    for I := 0 to ControlCount - 1 do
      if Supports(Controls[I], IUWPControl) then
        (Controls[I] as IUWPControl).UpdateColorization(IncludeChildren);
end;

procedure TUWPScrollBox.UpdateMiniSB;
var
  LSB: TControlScrollBar;
  LControlSize: Integer;
  LThumbPos, LThumbSize: Integer;
begin
  // Get orientation values
  if FScrollOrientation = oVertical then
  begin
    LSB := VertScrollBar;
    LControlSize := Height;
  end
  else
  begin
    LSB := HorzScrollBar;
    LControlSize := Width;
  end;

  if (LSB.Range = 0) or (LSB.Range < LControlSize) then
  begin
    MiniSB.Visible := False;
    Exit;
  end;

  LThumbSize := Round(LControlSize * LControlSize / LSB.Range);
  LThumbPos := Round(LControlSize * LSB.Position / LSB.Range);

  if FScrollOrientation = oVertical then
    TControl(MiniSB).SetBounds(Width - MiniSBMargin - MiniSBThickness, LThumbPos, MiniSBThickness, LThumbSize)
  else
    TControl(MiniSB).SetBounds(LThumbPos, Height - MiniSBMargin - MiniSBThickness, LThumbSize, MiniSBThickness);
end;

procedure TUWPScrollBox.WMSize(var AMsg: TWMSize);
begin
  inherited;
  if FScrollBarStyle <> sbsFull then
    SetOldSBVisible(False);
end;

end.
