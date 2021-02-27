unit UWP.Panel;

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, Windows, Forms, Graphics,
  UWP.Classes, UWP.ColorManager, UWP.Colors, UWP.Utils;

type
  TUWPPanel = class(TPanel, IUWPControl)
  private
    var AccentColor, BackColor, TextColor: TColor;

    FBarMargin: Integer;
    FBarPosition: TUWPDirection;
    FBarThickness: Integer;
    FBarVisible: Boolean;
    FCustomAccentColor: TColor;
    FCustomBackColor: TUWPColorizationColorSet;
    FTransparent: Boolean;

    // Internal
    procedure UpdateColors;

    // Setters
    procedure SetBarMargin(const AValue: Integer);
    procedure SetBarPosition(const AValue: TUWPDirection);
    procedure SetBarThickness(const AValue: Integer);
    procedure SetBarVisible(const AValue: Boolean);
    procedure SetCustomAccentColor(const AValue: TColor);
    procedure SetTransparent(const AValue: Boolean);

    // Events for children
    procedure CustomBackColor_OnChange(Sender: TObject);

  protected
    procedure Paint; override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Interface
    function IsContainer: Boolean;
    procedure UpdateColorization(const IncludeChildren: Boolean);

  published
    property BarMargin: Integer read FBarMargin write FBarMargin default 10;
    property BarPosition: TUWPDirection read FBarPosition write SetBarPosition default dLeft;
    property BarThickness: Integer read FBarThickness write SetBarThickness default 5;
    property BarVisible: Boolean read FBarVisible write SetBarVisible default False;
    property CustomAccentColor: TColor read FCustomAccentColor write SetCustomAccentColor default $D77800;
    property CustomBackColor: TUWPColorizationColorSet read FCustomBackColor write FCustomBackColor;
    property Transparent: Boolean read FTransparent write SetTransparent default False;

    //Modify props
    property BevelOuter default bvNone;
    property ParentBackground default False;
    property FullRepaint default False;
  end;

implementation

uses
  UWP.Form, UWP.Graphics;

{ TUWPPanel }

constructor TUWPPanel.Create(AOwner: TComponent);
begin
  inherited;
  AccentColor := $D77800;
  BackColor := $E6E6E6;
  TextColor := GetTextColorFromBackground(BackColor);

  FBarMargin := 10;
  FBarPosition := dLeft;
  FBarThickness := 5;
  FBarVisible := False;

  FCustomAccentColor := $D77800;

  FCustomBackColor := TUWPColorizationColorSet.Create;
  FCustomBackColor.OnChange := CustomBackColor_OnChange;
  FCustomBackColor.Assign(PANEL_BACK);
  FTransparent := False;

  // Modify props
  BevelOuter := bvNone;
  ParentBackground := False;
  FullRepaint := False;

  Color := $E6E6E6;
end;

procedure TUWPPanel.CustomBackColor_OnChange(Sender: TObject);
begin
  UpdateColorization(True);
end;

destructor TUWPPanel.Destroy;
begin
  FCustomBackColor.Free;
  inherited;
end;

function TUWPPanel.IsContainer: Boolean;
begin
  Result := True;
end;

procedure TUWPPanel.Paint;
var
  LBarRect: TRect;
begin
  // Don't inherit
  //inherited;

  // Draw background
  if not FTransparent then
  begin
    Canvas.Brush.Style := bsSolid;
    //Canvas.Brush.Color := BackColor;
    Canvas.Brush.Handle := CreateSolidBrushWithAlpha(BackColor);
    Canvas.FillRect(Rect(0, 0, Width, Height));
  end;

  // Draw bar
  if FBarVisible then
  begin
    //Canvas.Brush.Color := AccentColor;
    Canvas.Brush.Handle := CreateSolidBrushWithAlpha(AccentColor);
    case FBarPosition of
      dLeft:
        LBarRect := Rect(0, FBarMargin, FBarThickness, Height - FBarMargin);
      dTop:
        LBarRect := Rect(FBarMargin, 0, Width - FBarMargin, FBarThickness);
      dRight:
        LBarRect := Rect(Width - FBarThickness, FBarMargin, Width, Height - FBarMargin);
      dBottom:
        LBarRect := Rect(FBarMargin, Height - FBarThickness, Width - FBarMargin, Height);
    end;
    Canvas.FillRect(LBarRect);
  end;

  // Draw text
  if ShowCaption then
  begin
    Canvas.Font.Assign(Font);
    Canvas.Font.Color := TextColor;
    Canvas.Brush.Style := bsClear;
    DrawTextRect(Canvas, Alignment, VerticalAlignment, Rect(0, 0, Width, Height), Caption, False);
  end;
end;

procedure TUWPPanel.SetBarMargin(const AValue: Integer);
begin
  if AValue <> FBarMargin then
  begin
    FBarMargin := AValue;
    Invalidate;
  end;
end;

procedure TUWPPanel.SetBarPosition(const AValue: TUWPDirection);
begin
  if AValue <> FBarPosition then
  begin
    FBarPosition := AValue;
    Invalidate;
  end;
end;

procedure TUWPPanel.SetBarThickness(const AValue: Integer);
begin
  if AValue <> FBarThickness then
  begin
    FBarThickness := AValue;
    Invalidate
  end;
end;

procedure TUWPPanel.SetBarVisible(const AValue: Boolean);
begin
  if AValue <> FBarVisible then
  begin
    FBarVisible := AValue;
    Invalidate;
  end;
end;

procedure TUWPPanel.SetCustomAccentColor(const AValue: TColor);
begin
  if AValue <> FCustomAccentColor then
  begin
    FCustomAccentColor := AValue;
    Invalidate;
  end;
end;

procedure TUWPPanel.SetTransparent(const AValue: Boolean);
begin
  if AValue <> FTransparent then
  begin
    FTransparent := AValue;
    ParentBackground := AValue;
    Invalidate;
  end;
end;

procedure TUWPPanel.UpdateColorization(const IncludeChildren: Boolean);
var
  I: Integer;
begin
  UpdateColors;
  Invalidate;

  // Update children too
  if IsContainer and IncludeChildren then
    for I := 0 to ControlCount - 1 do
      if Supports(Controls[I], IUWPControl) then
        (Controls[I] as IUWPControl).UpdateColorization(IncludeChildren);
end;

procedure TUWPPanel.UpdateColors;
var
  LCM: TUWPColorizationManager;
  LBackColor: TUWPColorizationColorSet;
begin
  LCM := SelectColorizationManager(Self);

  AccentColor := SelectAccentColor(LCM, CustomAccentColor);

  LBackColor := SelectColorSet(LCM, CustomBackColor, PANEL_BACK);
  BackColor := LBackColor.GetColor(LCM);

  TextColor := GetTextColorFromBackground(BackColor);

  Color := BackColor;
end;

end.
