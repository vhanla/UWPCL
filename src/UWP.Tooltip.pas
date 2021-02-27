unit UWP.Tooltip;

interface

uses
  Classes, Types, Windows, Messages, Controls, Graphics,
  UWP.Classes, UWP.Utils, UWP.Graphics, UWP.Colors;


type
  TUWPCustomTooltip = class(THintWindow)
  const
    VERT_SPACE: Byte = 5;
    HORZ_SPACE: Byte = 7;

  private
    var ShowShadow: Boolean;
    var BorderThickness: Byte;
    var BorderColor, BackColor: TColor;

  protected
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure Paint; override;
    procedure NCPaint(ADC: HDC); override;

  public
    constructor Create(AOwner: TComponent); override;
    function CalcHintRect(AMaxWidth: Integer; const AHint: string; AData: Pointer): TRect; override;
  end;

  TUWPLightTooltip = class(TUWPCustomTooltip)
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TUWPDarkTooltip = class(TUWPCustomTooltip)
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{ TUWPCustomTooltip }

function TUWPCustomTooltip.CalcHintRect(AMaxWidth: Integer; const AHint: string;
  AData: Pointer): TRect;
begin
  Canvas.Font.Assign(Font);

  Result := Rect(0, 0, AMaxWidth, 0);
  DrawText(Canvas.Handle, AHint, -1, Result,
    DT_CALCRECT or DT_LEFT or DT_WORDBREAK or DT_NOPREFIX or DrawTextBiDiModeFlagsReadingOnly);

  Inc(Result.Right, 2 * (HORZ_SPACE + BorderThickness));
  Inc(Result.Bottom, 2 * (VERT_SPACE + BorderThickness));
end;

constructor TUWPCustomTooltip.Create(AOwner: TComponent);
begin
  inherited;

  ShowShadow := TOOLTIP_SHADOW;
  BorderThickness := TOOLTIP_BORDER_THICKNESS;
  Font.Name := TOOLTIP_FONT_NAME;
  Font.Size := TOOLTIP_FONT_SIZE;
end;

procedure TUWPCustomTooltip.CreateParams(var AParams: TCreateParams);
begin
  inherited;
  AParams.Style := AParams.Style and not WS_BORDER;

  if not ShowShadow then
    AParams.WindowClass.style := AParams.WindowClass.style and not CS_DROPSHADOW;
end;

procedure TUWPCustomTooltip.NCPaint(ADC: HDC);
begin
  //inherited; // do nothing

end;

procedure TUWPCustomTooltip.Paint;
var
  LTextRect: TRect;
begin
  // Don't inherit
  //inherited;

  // Draw background
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := BackColor;
  Canvas.FillRect(Rect(0, 0, Width, Height));

  // Draw border
  Canvas.Brush.Style := bsClear;
  DrawBorder(Canvas, Rect(0, 0, Width, Height), BorderColor, BorderThickness);

  // Draw Text
  Canvas.Font.Assign(Font);
  Canvas.Font.Color := GetTextColorFromBackground(BackColor);

  LTextRect := Rect(
    HORZ_SPACE + BorderThickness, VERT_SPACE + BorderThickness,
    Width - HORZ_SPACE - BorderThickness, Height - VERT_SPACE - BorderThickness);

  DrawText(Canvas.Handle, Caption, -1, LTextRect, DT_WORDBREAK or DT_LEFT or DT_VCENTER or DT_END_ELLIPSIS);
end;

{ TUWPLightTooltip }

constructor TUWPLightTooltip.Create(AOwner: TComponent);
begin
  inherited;
  BackColor := TOOLTIP_BACK.LightColor;
  BorderColor := TOOLTIP_BORDER.LightColor;
end;

{ TUWPDarkTooltip }

constructor TUWPDarkTooltip.Create(AOwner: TComponent);
begin
  inherited;
  BackColor := TOOLTIP_BACK.DarkColor;
  BorderColor := TOOLTIP_BORDER.DarkColor;
end;

end.
