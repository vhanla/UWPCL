unit UWP.FormShadow;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, GDIPAPI, GDIPOBJ, Vcl.Imaging.PNGImage, ActiveX;

type
  TfrmShadow = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
    FShadowActive, FShadowInactive: TGPBitmap;
    FShadowState: Boolean;
    FShadowActiveRect, FShadowInactiveRect: TRect; // each shadow might have different margins
    FShadowBorderSize: Integer; //square to pick on each corner and sides to use as template
    procedure SetShadowState(const AValue: Boolean);
    procedure UpdateLayeredShadow;
  public
    { Public declarations }
    FMargins: TRect;
  published
    { Published declarations }
    property ActivateShadow: Boolean read FShadowState write FShadowState;
  end;

//var
//  frmShadow: TfrmShadow;

implementation

{$R *.dfm}

procedure TfrmShadow.FormCreate(Sender: TObject);
var
  LStream: TStream;
  LStreamAdapter: IStream;
  LAlphaChannelUsed: Boolean;
begin
  // Preload both pictures
  LStream := TResourceStream.Create(HInstance, 'SHADOWACTIVE', RT_RCDATA);
  try
    LStreamAdapter := TStreamAdapter.Create(LStream);
    try
      FShadowActive := TGPBitmap.Create(LStreamAdapter);
    finally
      LStreamAdapter := nil;
    end;
  finally
    FreeAndNil(LStream);
  end;
  FShadowBorderSize := 100;
  FShadowActiveRect := Rect(48, 25, 48, 73);

  LStream := TResourceStream.Create(HInstance, 'SHADOWINACTIVE', RT_RCDATA);
  try
    LStreamAdapter := TStreamAdapter.Create(LStream);
    try
      FShadowInactive := TGPBitmap.Create(LStreamAdapter);
    finally
      LStreamAdapter := nil;
    end;
  finally
    FreeAndNil(LStream);
  end;
  FShadowInactiveRect := Rect(36, 27, 36, 43);
  FMargins := Rect(48, 27, 48, 73);

  BorderStyle := bsNone;
  SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) or WS_EX_LAYERED or WS_EX_TRANSPARENT or WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE);
  ActivateShadow := True;
end;

procedure TfrmShadow.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FShadowActive);
  FreeAndNil(FShadowInactive);
end;

procedure TfrmShadow.FormResize(Sender: TObject);
begin
  UpdateLayeredShadow;
end;

procedure TfrmShadow.SetShadowState(const AValue: Boolean);
begin
  FShadowState := AValue;
  UpdateLayeredShadow;
end;

procedure TfrmShadow.UpdateLayeredShadow;
type
  PTGPBitmap = ^TGPBitmap;
var
  LBlendFunction: TBlendFunction;
  LBitmap: TBitmap;
  LBitmapPoint: TPoint;
  LBitmapHandle: HBITMAP;
  LBitmapSize: TSize;
  LBmp: TGPGraphics;
  LBuf: TGPBitmap;
  LRect: TGPRect;
  LShadowPicture: PTGPBitmap;
  LShadowSize: TSize;
  LMarginOffset: TRect;
begin
  LBitmap := TBitmap.Create;
  try
    LBuf := TGPBitmap.Create(ClientWidth, ClientHeight, 0, PixelFormat32bppARGB, nil);
    try
      LBmp := TGPGraphics.Create(LBuf);
      try
        LBmp.SetPixelOffsetMode(PixelOffsetModeHalf); // correct stretching
        LBmp.Clear(MakeColor(0, 0, 0, 0));
        LBmp.SetInterpolationMode(InterpolationModeNearestNeighbor);

        if FShadowState then
        begin
          LMarginOffset := Rect(FMargins.Left - FShadowActiveRect.Left,
                           FMargins.Top - FShadowActiveRect.Top,
                           FMargins.Right - FShadowActiveRect.Right,
                           FMargins.Bottom - FShadowActiveRect.Bottom);
          LShadowPicture := @FShadowActive;
          LShadowSize.cx := FShadowActive.GetWidth;
          LShadowSize.cy := FShadowActive.GetHeight;
        end
        else
        begin
          LMarginOffset := Rect(FMargins.Left - FShadowInactiveRect.Left,
                           FMargins.Top - FShadowInactiveRect.Top,
                           FMargins.Right - FShadowInactiveRect.Right,
                           FMargins.Bottom - FShadowInactiveRect.Bottom);
          LShadowPicture := @FShadowInactive;
          LShadowSize.cx := FShadowInactive.GetWidth;
          LShadowSize.cy := FShadowInactive.GetHeight;
        end;

        // Let's draw

        // TopLeft
        LRect.X := LMarginOffset.Left; LRect.Y := LMarginOffset.Top;
        LRect.Width := FShadowBorderSize; LRect.Height := FShadowBorderSize;
        LBmp.DrawImage(LShadowPicture^, LRect, 0, 0, FShadowBorderSize, FShadowBorderSize, UnitPixel);
        // Top
        LRect.X := LMarginOffset.Left + FShadowBorderSize; LRect.Y := LMarginOffset.Top;
        LRect.Width := ClientWidth - LMarginOffset.Left - LMarginOffset.Right - FShadowBorderSize * 2; LRect.Height := FShadowBorderSize;
        LBmp.DrawImage(LShadowPicture^, LRect, FShadowBorderSize, 0, FShadowBorderSize, FShadowBorderSize, UnitPixel);
        // TopRight
        LRect.X := ClientWidth - FShadowBorderSize - LMarginOffset.Right; LRect.Y := LMarginOffset.Top;
        LRect.Width := FShadowBorderSize; LRect.Height := FShadowBorderSize;
        LBmp.DrawImage(LShadowPicture^, LRect, LShadowSize.cx - FShadowBorderSize, 0, FShadowBorderSize, FShadowBorderSize, UnitPixel);
        // Left
        LRect.X := LMarginOffset.Left; LRect.Y := LMarginOffset.Top + FShadowBorderSize;
        LRect.Width := FShadowBorderSize; LRect.Height := ClientHeight - LMarginOffset.Top - LMarginOffset.Bottom - FShadowBorderSize * 2;
        LBmp.DrawImage(LShadowPicture^, LRect, 0, FShadowBorderSize, FShadowBorderSize, LShadowSize.cy - FShadowBorderSize * 2, UnitPixel);
        // Right
        LRect.X := ClientWidth - FShadowBorderSize - LMarginOffset.Right; LRect.Y := LMarginOffset.Top + FShadowBorderSize;
        LRect.Width := FShadowBorderSize; LRect.Height := ClientHeight - LMarginOffset.Top - LMarginOffset.Bottom - FShadowBorderSize * 2;
        LBmp.DrawImage(LShadowPicture^, LRect, LShadowSize.cx - FShadowBorderSize, FShadowBorderSize, FShadowBorderSize, LShadowSize.cy - FShadowBorderSize * 2, UnitPixel);
        // BottomLeft
        LRect.X := LMarginOffset.Left; LRect.Y := ClientHeight - FShadowBorderSize - LMarginOffset.Bottom;
        LRect.Width := FShadowBorderSize; LRect.Height := FShadowBorderSize;
        LBmp.DrawImage(LShadowPicture^, LRect, 0, LShadowSize.cy - FShadowBorderSize, FShadowBorderSize, FShadowBorderSize, UnitPixel);
        // Bottom
        LRect.X := LMarginOffset.Left + FShadowBorderSize; LRect.Y := ClientHeight - FShadowBorderSize - LMarginOffset.Bottom;
        LRect.Width := ClientWidth - LMarginOffset.Left - LMarginOffset.Right - FShadowBorderSize * 2; LRect.Height := FShadowBorderSize;
        LBmp.DrawImage(LShadowPicture^, LRect, FShadowBorderSize, LShadowSize.cy - FShadowBorderSize, LShadowSize.cy - FShadowBorderSize * 2, FShadowBorderSize, UnitPixel);
        // BottomRight
        LRect.X := ClientWidth - FShadowBorderSize - LMarginOffset.Right; LRect.Y := ClientHeight - FShadowBorderSize - LMarginOffset.Bottom;
        LRect.Width := FShadowBorderSize; LRect.Height := FShadowBorderSize;
        LBmp.DrawImage(LShadowPicture^, LRect, LShadowSize.cx - FShadowBorderSize, LShadowSize.cy - FShadowBorderSize, FShadowBorderSize, FShadowBorderSize, UnitPixel);
      finally
        FreeAndNil(LBmp);
      end;

      LBuf.GetHBITMAP(MakeColor(0, 0, 0, 0), LBitmapHandle);
    finally
      FreeAndNil(LBuf);
    end;

    LBitmap.Handle := LBitmapHandle;

    LBitmapSize.cx := LBitmap.Width;
    LBitmapSize.cy := LBitmap.Height;

    LBlendFunction.BlendOp := AC_SRC_OVER;
    LBlendFunction.BlendFlags := 0;
    LBlendFunction.SourceConstantAlpha := 255;
    LBlendFunction.AlphaFormat := AC_SRC_ALPHA;

    LBitmapPoint := Point(0, 0);

    UpdateLayeredWindow(Handle, 0, nil, @LBitmapSize, LBitmap.Canvas.Handle,
      @LBitmapPoint, 0, @LBlendFunction, ULW_ALPHA);
  finally
    FreeAndNil(LBitmap);
  end;
end;

end.
