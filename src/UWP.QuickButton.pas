unit UWP.QuickButton;

interface

uses
  Classes, Windows, Types, Messages, Controls, Forms, Graphics,
  UWP.Classes, UWP.ColorManager, UWP.Utils, UWP.Graphics, UWP.Colors;

type
  TUWPQuickButtonStyle = (qbsNone, qbsQuit, qbsMax, qbsMin, qbsHighlight);

  TUWPQuickButton = class(TGraphicControl, IUWPControl)
  private
    var BackColor, TextColor: TColor;

    FCustomBackColor: TUWPColorizationColorSet;
    FCustomAccentColor: TColor;

    FButtonState: TUWPControlState;
    FButtonStyle: TUWPQuickButtonStyle;

    // Internal
    procedure UpdateColors;

    // Events for children
    procedure CustomBackColor_OnChange(Sender: TObject);

    // Setters
    procedure SetButtonState(const AValue: TUWPControlState);
    procedure SetButtonStyle(const AValue: TUWPQuickButtonStyle);
    procedure SetCustomAccentColor(const AValue: TColor);

    // Message handling
    procedure WMLButtonDown(var AMsg: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure WMLButtonUp(var AMsg: TWMLButtonUp); message WM_LBUTTONUP;
    procedure CMMouseEnter(var AMsg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var AMsg: TMessage); message CM_MOUSELEAVE;
    procedure CMTextChanged(var AMsg: TMessage); message CM_TEXTCHANGED;

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
    property CustomAccentColor: TColor read FCustomAccentColor write SetCustomAccentColor default $D77800;

    property ButtonState: TUWPControlState read FButtonState write SetButtonState default csNone;
    property ButtonStyle: TUWPQuickButtonStyle read FButtonStyle write SetButtonStyle default qbsNone;

    // Modify default props
    property Height default 32;
    property Width default 45;
    property Caption;
    // add Props
    property Align;
    property Anchors;
    property AutoSize;
    property BiDiMode;
    property Color;
    property Constraints;
    property DragCursor;
    property DragKind;
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
    property StyleElements;
    // add events
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

uses
  UWP.FontIcons;

{ TUWPQuickButton }

procedure TUWPQuickButton.CMMouseEnter(var AMsg: TMessage);
begin
  if not Enabled then Exit;
  ButtonState := csHover;
  inherited;
end;

procedure TUWPQuickButton.CMMouseLeave(var AMsg: TMessage);
begin
  if not Enabled then Exit;
  ButtonState := csNone;
  inherited;
end;

procedure TUWPQuickButton.CMTextChanged(var AMsg: TMessage);
begin
  inherited;
  Invalidate;
end;

constructor TUWPQuickButton.Create(AOwner: TComponent);
begin
  inherited;

  ControlStyle := ControlStyle - [csDoubleClicks];

  FButtonState := csNone;
  FButtonStyle := qbsNone;
  FCustomAccentColor := $D77800;

  FCustomBackColor := TUWPColorizationColorSet.Create;
  FCustomBackColor.OnChange := CustomBackColor_OnChange;
  FCustomBackColor.Assign(QUICKBUTTON_BACK);

  // Modify default props
  Caption := UF_BACK;
  Font.Name := 'Segoe MDL2 Assets';
  Font.Size := 10;
  Height := 32;
  Width := 45;

  UpdateColors;
end;

procedure TUWPQuickButton.CustomBackColor_OnChange(Sender: TObject);
begin
  UpdateColors;
  Invalidate;
end;

destructor TUWPQuickButton.Destroy;
begin
  FCustomBackColor.Free;
  inherited;
end;

function TUWPQuickButton.IsContainer: Boolean;
begin
  Result := False;
end;

procedure TUWPQuickButton.Paint;
begin
  inherited;

  // Draw background
  if ButtonState <> csNone then
  begin
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Handle := CreateSolidBrushWithAlpha(BackColor, 255);
    Canvas.FillRect(Rect(0, 0, Width, Height));
  end;

  // Draw Text
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Assign(Font);
  Canvas.Font.Color := TextColor;
  DrawTextRect(Canvas, taCenter, taVerticalCenter, Rect(0, 0, Width, Height), Caption, False);
end;

procedure TUWPQuickButton.SetButtonState(const AValue: TUWPControlState);
begin
  if AValue <> FButtonState then
  begin
    FButtonState := AValue;
    UpdateColors;
    Invalidate;
  end;
end;

procedure TUWPQuickButton.SetButtonStyle(const AValue: TUWPQuickButtonStyle);
begin
  if AValue <> FButtonStyle then
  begin
    FButtonStyle := AValue;

    case AValue of
      qbsNone, qbsHighlight:
      ;
      qbsQuit:
        Caption := UF_CLOSE;
      qbsMax:
        Caption := UF_MAXIMIZE;
      qbsMin:
        Caption := UF_MINIMIZE;
    end;
  end;
end;

procedure TUWPQuickButton.SetCustomAccentColor(const AValue: TColor);
begin
  if AValue <> FCustomAccentColor then
  begin
    FCustomAccentColor := AValue;
    UpdateColors;
    Invalidate;
  end;
end;

procedure TUWPQuickButton.UpdateColorization(const IncludeChildren: Boolean);
begin
  UpdateColors;
  Invalidate;
end;

procedure TUWPQuickButton.UpdateColors;
var
  LCM: TUWPColorizationManager;
  LBackColor: TUWPColorizationColorSet;
  LIsDark: Boolean;
  LBaseColor, LAccentColor: TColor;
begin
  LCM := SelectColorizationManager(Self);
  LIsDark := (LCM <> nil) and (LCM.Colorization = ucDark);
  LAccentColor := SelectAccentColor(LCM, CustomAccentColor);

  if ButtonState = csNone then
  begin
    ParentColor := True;
    BackColor := Color;
  end
  else
  begin
    // Select BaseColor
    case ButtonStyle of
      qbsQuit:
        LBaseColor := $2311E8;
      qbsHighlight:
        LBaseColor := LAccentColor;
      else
      begin
        LBackColor := SelectColorSet(LCM, CustomBackColor, QUICKBUTTON_BACK);
        if ButtonStyle = qbsQuit then
          LBaseColor := $2311E8
        else
          LBaseColor := LBackColor.GetColor(LCM);
      end;
    end;

    // Update BackColor using obtained LBaseColor
    case ButtonState of
      csHover:
        BackColor := LBaseColor;
      csPress:
        if ButtonStyle in [qbsHighlight, qbsQuit] then
        begin
          BackColor := BrightenColor(LBaseColor, 10);
        end
        else
        begin
          if not LIsDark then
            BackColor := ColorChangeLightness(LBaseColor, 160)
          else
            BackColor := ColorChangeLightness(LBaseColor, 80);
        end;
    end;
  end;
  // Get Text color from background
  TextColor := GetTextColorFromBackground(BackColor);
end;

procedure TUWPQuickButton.WMLButtonDown(var AMsg: TWMLButtonDown);
begin
  if not Enabled then Exit;
  ButtonState := csPress;
  inherited;
end;

procedure TUWPQuickButton.WMLButtonUp(var AMsg: TWMLButtonUp);
var
  LParentForm: TCustomForm;
//  LFullScreen: Boolean;
  LMousePos: TPoint;
begin
  if not Enabled then Exit;

  LMousePos := ScreenToClient(Mouse.CursorPos);
  if PtInRect(GetClientRect, LMousePos) then
  begin
    // Default actions for Quit, Max, Min
    if ButtonStyle in [qbsQuit, qbsMax, qbsMin] then
    begin
      LParentForm := GetParentForm(Self, True);
      //TODO: FullScreen
      case ButtonStyle of
        qbsQuit:
          LParentForm.Close;

        qbsMin:
          LParentForm.WindowState := wsMinimized;

        qbsMax:
          begin
            ReleaseCapture;
            if LParentForm.WindowState <> wsNormal then
              SendMessage(LParentForm.Handle, WM_SYSCOMMAND, SC_RESTORE, 0)
            else
              SendMessage(LParentForm.Handle, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
          end;
      end;
    end;
  end;

  ButtonState := csHover;
  inherited;
end;

end.
