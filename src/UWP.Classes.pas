unit UWP.Classes;

interface

uses
  Classes, VCL.Graphics, VCL.Controls, Windows;

const
  WCA_ACCENT_POLICY = 19;
  ACCENT_ENABLE_NORMAL = 0;
  ACCENT_ENABLE_GRADIENT = 1;
  ACCENT_ENABLE_TRANSPARENTGRADIENT = 2;
  ACCENT_ENABLE_BLURBEHIND = 3;
  ACCENT_ENABLE_ACRYLICBLURBEHIND = 4;
  DRAW_LEFT_BORDER   = $20;
  DRAW_TOP_BORDER    = $40;
  DRAW_RIGHT_BORDER  = $80;
  DRAW_BOTTOM_BORDER = $100;


type
  TUWPColorization = (ucLight, ucDark);
  TUWPOrientation = (oHorizontal, oVertical);
  TUWPDirection = (dLeft, dTop, dRight, dBottom);
  TUWPControlState = (csNone, csHover, csPress);

  TUWPImageKind = (ikFontIcon, ikImage);

  AccentPolicy = packed record
    AccentState:    Integer;
    AccentFlags:    Integer;
    GradientColor:  Integer;
    AnimationId:    Integer;
  end;

  WindowCompositionAttributeData = packed record
    Attribute:  THandle;
    Data:       Pointer;
    SizeOfData: ULONG;
  end;

implementation

end.
