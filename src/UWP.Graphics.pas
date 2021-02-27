unit UWP.Graphics;

interface

uses
  Classes, Types, Windows, Graphics, Themes;

procedure GetCenterPos(AWidth, AHeight: Integer; ARect: TRect; out X, Y: Integer);
procedure DrawTextRect(const Canvas: TCanvas; HAlign: TAlignment; VAlign: TVerticalAlignment;
  Rect: TRect; Text: string; TextOnGlass: Boolean);
procedure DrawBorder(const ACanvas: TCanvas; ARect: TRect; AColor: TColor; AThickness: Byte);

implementation

uses UWP.Utils;

const
  HAlignments: Array[TAlignment] of LongInt = (DT_LEFT, DT_RIGHT, DT_CENTER);
  VAlignments: Array[TVerticalAlignment] of LongInt = (DT_TOP, DT_BOTTOM, DT_VCENTER);

procedure GetCenterPos(AWidth, AHeight: Integer; ARect: TRect; out X, Y: Integer);
begin
  X := ARect.Left + (ARect.Width - AWidth) div 2;
  Y := ARect.Top + (ARect.Height - AHeight) div 2;
end;

procedure DrawTextRect(const Canvas: TCanvas; HAlign: TAlignment; VAlign: TVerticalAlignment;
  Rect: TRect; Text: string; TextOnGlass: Boolean);
var
  LFlags: Cardinal;
begin
  LFlags := DT_EXPANDTABS or DT_SINGLELINE or HAlignments[HAlign] or VAlignments[VAlign];

  if not TextOnGlass then
    DrawText(Canvas.Handle, Text, Length(Text), Rect, LFlags);
end;

procedure DrawBorder(const ACanvas: TCanvas; ARect: TRect; AColor: TColor; AThickness: Byte);
var
  LTopLeft, LBottomRight: Byte;
begin
  if AThickness <> 0 then
  begin
    LTopLeft := AThickness div 2;
    if AThickness and 1 <> 1 then
      LBottomRight := LTopLeft  - 1
    else
      LBottomRight := LTopLeft;

    ACanvas.Pen.Color := CreateSolidBrushWithAlpha(AColor);
    ACanvas.Pen.Width := AThickness;
    ACanvas.Rectangle(Rect(LTopLeft, LTopLeft, ARect.Width - LBottomRight, ARect.Height - LBottomRight));
  end;
end;

end.
