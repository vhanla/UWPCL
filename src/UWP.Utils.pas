unit UWP.Utils;

interface

uses
  SysUtils, Types, Windows, VCL.Graphics, VCL.GraphUtil, VCL.Themes,
  UWP.Classes, UWP.Types, DWMApi, UXTheme;

// Form
function EnableBlur(FormHandle: HWND; AccentState: Integer): Integer;

// Glass support
function CreatePreMultipliedRGBQuad(Color: TColor; Alpha: Byte = $FF): TRGBQuad;
function CreateSolidBrushWithAlpha(Color: TColor; Alpha: Byte = $FF): HBRUSH;

// Color
function BrightenColor(AColor: TColor; ADelta: Integer): TColor;
function ColorChangeLightness(AColor: TColor; AValue: Integer): TColor;
function GetTextColorFromBackground(BackColor: TColor): TColor;



function SetWindowCompositionAttribute(Wnd: HWND; const AttrData: WindowCompositionAttributeData): HRESULT; stdcall;
  external 'win32u.dll' Name 'NtUserSetWindowCompositionAttribute';

implementation

function EnableBlur(FormHandle: HWND; AccentState: Integer): Integer;
var
  LAccent: AccentPolicy;
  LData: WindowCompositionAttributeData;
  bb: DWM_BLURBEHIND;
  mrgn: TMargins;
begin
  LAccent.AccentState := AccentState;
  // draws shadow
  LAccent.AccentFlags := DRAW_LEFT_BORDER or DRAW_TOP_BORDER or DRAW_RIGHT_BORDER or DRAW_BOTTOM_BORDER;//2
  LAccent.GradientColor := 0;//$00FFFFFF;
//  LAccent.GradientColor := (1 shl 24) + ((clBlack and $FF00FF00) + ((clBlack and $00FF0000)shr 16) + ((clBlack and $000000FF) shl 16))and $00FFFFFF;
  LAccent.AnimationId := 0;
  LData.Attribute := WCA_ACCENT_POLICY;
  LData.SizeOfData := SizeOf(LAccent);
  LData.Data := @LAccent;
  bb.dwFlags := DWM_BB_ENABLE;
  bb.fEnable := True;
  bb.hRgnBlur := 0;
  bb.fTransitionOnMaximized := False;
//  DwmEnableBlurBehindWindow(FormHandle, bb);
//  mrgn.cxLeftWidth := -1;
//  mrgn.cxRightWidth := -1;
//  mrgn.cyTopHeight := -1;
//  mrgn.cyBottomHeight := -1;
//  DwmExtendFrameIntoClientArea(FormHandle, mrgn);
  Result := SetWindowCompositionAttribute(FormHandle, LData);
  SetWindowPos(FormHandle, 0, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOMOVE or SWP_NOSIZE and not SWP_DRAWFRAME);
end;

function CreatePreMultipliedRGBQuad(Color: TColor; Alpha: Byte = $FF): TRGBQuad;
begin
  Color := ColorToRGB(Color);
  Result.rgbBlue := MulDiv(GetBValue(Color), Alpha, $FF);
  Result.rgbGreen := MulDiv(GetGValue(Color), Alpha, $FF);
  Result.rgbRed := MulDiv(GetRValue(Color), Alpha, $FF);
  Result.rgbReserved := Alpha;
end;

function CreateSolidBrushWithAlpha(Color: TColor; Alpha: Byte = $FF): HBRUSH;
var
  Info: TBitmapInfo;
begin
  FillChar(Info, SizeOf(Info), 0);
  with Info.bmiHeader do
  begin
    biSize := SizeOf(Info.bmiHeader);
    biWidth := 1;
    biHeight := 1;
    biPlanes := 1;
    biBitCount := 32;
    biCompression := BI_RGB;
  end;
  Info.bmiColors[0] := CreatePreMultipliedRGBQuad(Color, Alpha);
  Result := CreateDIBPatternBrushPt(@Info, 0);
end;

function BrightenColor(AColor: TColor; ADelta: Integer): TColor;
var
  H, S, L: Word;
begin
  ColorRGBToHLS(AColor, H, L, S);
  L := L + ADelta;
  Result := ColorHLSToRGB(H, L, S);
end;

function ColorChangeLightness(AColor: TColor; AValue: Integer): TColor;
var
  H, S, L: Word;
begin
  ColorRGBToHLS(AColor, H, L, S);
  Result := ColorHLSToRGB(H, AValue, S);
end;

function GetTextColorFromBackground(BackColor: TColor): TColor;
var
  C: Integer;
  R, G, B: Byte;
begin
  C := ColorToRGB(BackColor);
  R := GetRValue(C);
  G := GetGValue(C);
  B := GetBValue(C);

  if (R = G) and (G = B) then  // b/w
  begin
    if C < $808080 then
      Result := $FFFFFF
    else
      Result := $000000;
  end
  else
  begin
    if 0.99 * R + 0.587 * G + 0.114 * B > 156 then
      Result := $000000
    else
      Result := $FFFFFF;
  end;
end;

end.
