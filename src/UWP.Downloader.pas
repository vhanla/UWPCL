{
  TUWPDownloader
  Mimics Microsoft Store's downloader, i.e. the progress bar in a list.
}
unit UWP.Downloader;

interface

uses
  Classes, SysUtils, Types, Messages, Controls, ExtCtrls, ImgList, Graphics, Windows,
  UWP.Classes, UWP.ColorManager, UWP.Colors, UWP.Graphics, UWP.Utils, UWP.Form, UWP.IntAnimation,
  System.Net.HttpClient;

type
  TUWPDownloaderStyle = (dsHorizontal, dsVertical);

  TUWPDownloaderSelectMode = (dsmNone, dsmSelect);

  TUWPDownloaderStatus = (dtNoAction, dtDownloading, dtPaused, dtFinished, dtFailed);

  TUWPDownloader = class(TPanel, IUWPControl)
  private
    var BackColor, TextColor, DetailColor, ExtraDetailColor,
        StatusColor, ProgressTopColor, ProgressBottomColor: TColor;
    var ImgRect, TextRect, DetailRect, ExtraDetailRect,
      StatusRect, ProgressTopRect, ProgressBottomRect: TRect;
    var DownloadBtnRect, CancelBtnRect, RestartBtnRect: TRect;
    var FillColor: TColor;
    var FillRect: TRect;

    // progress bar
    FAniSet: TIntAniSet;
    FCustomFillColor: TColor;
    FProgressHeight: Integer;

    FValue: Byte;

    FOnChange: TNotifyEvent;

    // downloader itself

    FClient: THTTPClient;
    FGlobalStart: Cardinal;
    FGlobalStep: Cardinal;
    FAsyncResult: IAsyncResult;
    FDownloaderStream: TStream;
    FSize: Int64;
    FURL: string;
    FUA: string;
    FHeader: string;
    FSavePath: string;

    // gui

    FIconFont: TFont;
    FCustomBackColor: TUWPStateColorSet;

    FDownloaderState: TUWPControlState;
    FDownloaderStyle: TUWPDownloaderStyle;

    FImageKind: TUWPImageKind;
    FImages: TCustomImageList;
    FImageIndex: Integer;
    FFontIcon: string;
    FDownloadStartIcon: string;
    FDownloadPauseIcon: string;
    FDownloadCancelIcon: string;
    FDownloadRestartIcon: string;

    FImageSpace: Integer;
    FSpacing: Integer;

    FDetail: string;
    FExtraDetail: string;
    FStatus: string;
    FProgressTop: string;
    FProgressBottom: string;

    FTransparent: Boolean;

//    FSelectMode: TUWPDownloaderSelectMode;
//    FSelected: Boolean;

    // Internal
    procedure UpdateColors;
    procedure UpdateRects;

    // Setters
    procedure SetValue(const AValue: Byte);

    procedure SetDownloaderState(const AValue: TUWPControlState);
    procedure SetDownloaderStyle(const AValue: TUWPDownloaderStyle);

    procedure SetImageKind(const AValue: TUWPImageKind);
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetImageIndex(const AValue: Integer);

    procedure SetFontIcon(const AValue: string);
    procedure SetDownloadStartIcon(const AValue: string);
    procedure SetDownloadPauseIcon(const AValue: string);
    procedure SetDownloadCancelIcon(const AValue: string);
    procedure SetDownloadRestartIcon(const AValue: string);

    procedure SetImageSpace(const AValue: Integer);
    procedure SetSpacing(const AValue: Integer);

    procedure SetDetail(const AValue: string);
    procedure SetExtraDetail(const AValue: string);
    procedure SetStatus(const AValue: string);
    procedure SetProgressTop(const AValue: string);
    procedure SetProgressBottom(const AValue: string);

    procedure SetTransparent(const AValue: Boolean);

    // Events for children
    procedure CustomBackColor_OnChange(Sender: TObject);

    // Message handling
    procedure WMLButtonDown(var AMsg: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure WMLButtonUp(var AMsg: TWMLButtonUp); message WM_LBUTTONUP;

    procedure CMMouseEnter(var AMsg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var AMsg: TMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var AMsg: TMessage); message CM_ENABLEDCHANGED;
    procedure CMTextChanged(var AMsg: TMessage); message CM_TEXTCHANGED;

  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure CreateWindowHandle(const AParams: TCreateParams); override;
    procedure ChangeScale(M, D: Integer; DpiChanged: Boolean); override;

    // download handling
    procedure DoReceiveDataEvent(const Sender: TObject; AContentLenght: Int64;
                      AReadCount: Int64; var Abort: Boolean);
    procedure DoEndDownload(const AsyncResult: IAsyncResult);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Loaded; override;

    // Interface
    function IsContainer: Boolean;
    procedure UpdateColorization(const IncludeChildren: Boolean);

    procedure GoToValue(AValue: Integer);

    // downloader
    procedure DoStartDownload;
  published
    // progress bar
    property AniSet: TIntAniSet read FAniSet write FAniSet;
    property CustomFillColor: TColor read FCustomFillColor write FCustomFillColor default $25B006;
    property ProgressHeight: Integer read FProgressHeight write FProgressHeight default 4;

    property Value: Byte read FValue write SetValue default 0;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    // client
    property URL: string read FURL write FURL nodefault;
    property Header: string read FHeader write FHeader nodefault;
    property UserAgent: string read FUA write FUA nodefault;
    property SavePath: string read FSavePath write FSavePath nodefault;

    // gui
    property IconFont: TFont read FIconFont write FIconFont;
    property CustomBackColor: TUWPStateColorSet read FCustomBackColor write FCustomBackColor;

    property DownloaderState: TUWPControlState read FDownloaderState write SetDownloaderState default csNone;
    property DownloaderStyle: TUWPDownloaderStyle read FDownloaderStyle write SetDownloaderStyle default dsHorizontal;

    property ImageKind: TUWPImageKind read FImageKind write SetImageKind default ikFontIcon;
    property Images: TCustomImageList read FImages write SetImages;
    property ImageIndex: Integer read FImageIndex write SetImageIndex default -1;

    property FontIcon: string read FFontIcon write SetFontIcon nodefault;
    property DownloadStartIcon: string read FDownloadStartIcon write SetDownloadStartIcon nodefault;
    property DownloadPauseIcon: string read FDownloadPauseIcon write SetDownloadPauseIcon nodefault;
    property DownloadCancelIcon: string read FDownloadCancelIcon write SetDownloadCancelIcon nodefault;
    property DownloadRestartIcon: string read FDownloadRestartIcon write SetDownloadRestartIcon nodefault;

    property ImageSpace: Integer read FImageSpace write SetImageSpace default 48;
    property Spacing: Integer read FSpacing write SetSpacing default 10;

    property Detail: string read FDetail write SetDetail nodefault;
    property ExtraDetail: string read FExtraDetail write SetExtraDetail nodefault;
    property Status: string read FStatus write SetStatus nodefault;
    property ProgressTop: string read FProgressTop write SetProgressTop nodefault;
    property ProgressBottom: string read FProgressBottom write SetProgressBottom nodefault;

    property Transparent: Boolean read FTransparent write SetTransparent default False;

//    property SelectMode: TUWPDownloaderSelectMode read FSelectMode write SetSelectMode default dsmNone;
//    property Selected: Boolean read GetSelected write SetSelected default False;

    // Modify default props
    property Height default 60;
    property Width default 998;

    property BevelOuter default bvNone;
    property ParentBackground default False;
    property TabStop default True;
    property FullRepaint default False;
  end;
implementation

uses
  UWP.FontIcons;

{ TUWPDownloader }

procedure TUWPDownloader.ChangeScale(M, D: Integer; DpiChanged: Boolean);
begin
  inherited;
  FImageSpace := MulDiv(ImageSpace, M, D);
  FSpacing := MulDiv(Spacing, M, D);
  IconFont.Height := MulDiv(IconFont.Height, M, D);
  UpdateRects;
end;

procedure TUWPDownloader.CMEnabledChanged(var AMsg: TMessage);
begin
  UpdateColors;
  Invalidate;
  inherited;
end;

procedure TUWPDownloader.CMMouseEnter(var AMsg: TMessage);
begin
  if not Enabled then Exit;
  DownloaderState := csHover;
  inherited;
end;

procedure TUWPDownloader.CMMouseLeave(var AMsg: TMessage);
begin
  if not Enabled then Exit;
  DownloaderState := csNone;
  inherited;
end;

procedure TUWPDownloader.CMTextChanged(var AMsg: TMessage);
begin
  UpdateRects;
  Invalidate;
  inherited;
end;

constructor TUWPDownloader.Create(AOwner: TComponent);
begin
  inherited;

  ControlStyle := ControlStyle - [csDoubleClicks];

  FDownloaderState := csNone;
  FImageKind := ikFontIcon;
  FImageIndex := -1;
  FFontIcon := UF_CLOUD;
  FDownloadStartIcon := UF_DOWNLOAD;
  FDownloadPauseIcon := UF_PAUSE;
  FDownloadCancelIcon := UF_CLOSE;
  FDownloadRestartIcon := UF_REFRESH;
  FImageSpace := 48;
  FSpacing := 10;
  FDetail := 'Detail';
  FExtraDetail := 'Extra Detail';
  FStatus := 'Status';
  FProgressTop := 'Message 1';
  FProgressBottom := '0kb/s';
  FTransparent := False;

  FIconFont := TFont.Create;
  IconFont.Name := 'Segoe MDL2 Assets';
  IconFont.Size := 16;

  FCustomBackColor := TUWPStateColorSet.Create;
  FCustomBackColor.OnChange := CustomBackColor_OnChange;
  FCustomBackColor.Assign(LISTBUTTON_BACK);

  // httpclient
  FClient := THTTPClient.Create;
  FClient.OnReceiveData := DoReceiveDataEvent;

  // progress bar
  FValue := 0;
  FCustomFillColor := $25B006;
  FAniSet := TIntAniSet.Create;
  FAniSet.QuickAssign(akOut, afkQuartic, 0, 250, 25);
  FProgressHeight := 4;

  // Modify default props
  BevelOuter := bvNone;
  ParentBackground := False;
  TabStop := True;
  FullRepaint := False;
  Width := 998;
  Height := 60;
end;

procedure TUWPDownloader.CreateWindowHandle(const AParams: TCreateParams);
begin
  inherited;
  UpdateColors;
  UpdateRects;
end;

procedure TUWPDownloader.CustomBackColor_OnChange(Sender: TObject);
begin
  UpdateColors;
  Invalidate;
end;

destructor TUWPDownloader.Destroy;
begin
  FClient.Free;
  FDownloaderStream.Free;
  FAniSet.Free;
  FIconFont.Free;
  FCustomBackColor.Free;
  inherited;
end;

procedure TUWPDownloader.DoEndDownload(const AsyncResult: IAsyncResult);
var
  LResponse: IHTTPResponse;
//  LStr: TStrings;
begin
  try
    LResponse := THTTPClient.EndAsyncHTTP(AsyncResult);
    TThread.Synchronize(nil,
      procedure
      begin
        if LResponse.StatusCode = 200 then
        begin
//          LStr := TStringList.Create;
//          try
//            LStr.LoadFromStream(FDownloaderStream);
//            Lstr.SaveToFile(FSavePath);
//          finally
//            LStr.Free;
//          end;
        end
        else
        begin
          // some error has ocurred

        end;
        Invalidate;
      end
    );
  finally
    LResponse := nil;
    FreeAndNil(FDownloaderStream);
    // show success or something
  end;
end;

procedure TUWPDownloader.DoReceiveDataEvent(const Sender: TObject;
  AContentLenght, AReadCount: Int64; var Abort: Boolean);
var
  LTime: Cardinal;
  LSpeed: Integer;
begin
  LTime := TThread.GetTickCount - FGlobalStart;
  LSpeed := (AReadCount * 1000) div LTime;
  TThread.Queue(nil,
    procedure
    begin
      FValue := Round(100 / FSize * AReadCount);
      FStatus := Format('%d KB/s', [LSpeed div 1024]);
    end
  );
  //if TThread.GetTickCount - FGlobalStep > 1000 then
  begin
//    FGlobalStep := TThread.GetTickCount;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPDownloader.DoStartDownload;
var
  LResponse: IHTTPResponse;
begin
  try
    LResponse := FClient.Head(FURL);
    FSize := LResponse.ContentLength;
    LResponse := nil;
    FValue := 0;
    FDownloaderStream := TFileStream.Create(FSavePath, fmCreate);
    FDownloaderStream.Position := 0;

    FGlobalStart := TThread.GetTickCount;

    FAsyncResult := FClient.BeginGet(DoEndDownload, FURL, FDownloaderStream);
  finally
    FAsyncResult := nil;
  end;
end;

procedure TUWPDownloader.GoToValue(AValue: Integer);
var
  LAni: TIntAni;
begin
  if not Enabled then Exit;

  LAni := TIntAni.Create(FValue, Value - FValue,
    procedure(V: Integer)
    begin
      Self.Value := V;
    end, nil);
  LAni.AniSet.Assign(Self.AniSet);
  LAni.Start;
end;

function TUWPDownloader.IsContainer: Boolean;
begin
  Result := False;
end;

procedure TUWPDownloader.Loaded;
begin
  inherited;
  UpdateColors;
  UpdateRects;
end;

procedure TUWPDownloader.Paint;
var
  LImgX, LImgY: Integer;
begin
  //inherited;

  // Paint Background
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Handle := CreateSolidBrushWithAlpha(BackColor, 255);
  Canvas.FillRect(Rect(0, 0, Width, Height));
  Canvas.Brush.Style := bsClear;

  // Draw Image
  if ImageKind = ikFontIcon then
  begin
    Canvas.Font.Assign(IconFont);
    Canvas.Font.Color := TextColor;

    DrawTextRect(Canvas, taCenter, taVerticalCenter, ImgRect, FontIcon, False);
  end
  else if (Images <> nil) and (ImageIndex >= 0) then
  begin
    GetCenterPos(Images.Width, Images.Height, ImgRect, LImgX, LImgY);
    Images.Draw(Canvas, LImgX, LImgY, ImageIndex, Enabled);
  end;

  // Draw Text
  Canvas.Font.Assign(Font);
  Canvas.Font.Color := TextColor;
  case DownloaderStyle of
    dsHorizontal, dsVertical:
      DrawTextRect(Canvas, taLeftJustify, taVerticalCenter, TextRect, Caption, False);
//    dsVertical:
//      DrawTextRect(Canvas, taCenter, taAlignTop, TextRect, Caption, False);
  end;

  // Draw Detail
  Canvas.Font.Color := DetailColor;
  case DownloaderStyle of
    dsHorizontal:
      DrawTextRect(Canvas, taLeftJustify, taVerticalCenter, DetailRect, Detail, False);
    dsVertical:
      DrawTextRect(Canvas, taLeftJustify, taAlignTop, DetailRect, Detail, False);
  end;

  // Draw ExtraDetail
  Canvas.Font.Color := ExtraDetailColor;
  case DownloaderStyle of
    dsHorizontal:
      DrawTextRect(Canvas, taLeftJustify, taVerticalCenter, ExtraDetailRect, ExtraDetail, False);
    dsVertical:
      DrawTextRect(Canvas, taLeftJustify, taAlignTop, ExtraDetailRect, ExtraDetail, False);
  end;

  // Draw Status
  Canvas.Font.Color := StatusColor;
  case DownloaderStyle of
    dsHorizontal:
      DrawTextRect(Canvas, taLeftJustify, taVerticalCenter, StatusRect, Status, False);
    dsVertical:
      DrawTextRect(Canvas, taLeftJustify, taAlignTop, StatusRect, Status, False);
  end;

  // Draw buttons
  Canvas.Font.Assign(IconFont);
  Canvas.Font.Color := TextColor;
  DrawTextRect(Canvas, taCenter, taVerticalCenter, RestartBtnRect, DownloadRestartIcon, False);
  DrawTextRect(Canvas, taCenter, taVerticalCenter, CancelBtnRect, DownloadCancelIcon, False);
  DrawTextRect(Canvas, taCenter, taVerticalCenter, DownloadBtnRect, DownloadStartIcon, False);

  // Progress bar
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Handle := CreateSolidBrushWithAlpha(FillColor, 255);
  Canvas.FillRect(FillRect);
  Canvas.Brush.Style := bsClear;
end;

procedure TUWPDownloader.Resize;
begin
  inherited;
  UpdateRects;
end;

procedure TUWPDownloader.SetDetail(const AValue: string);
begin
  if AValue <> FDetail then
  begin
    FDetail := AValue;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPDownloader.SetDownloadCancelIcon(const AValue: string);
begin
  if AValue <> FDownloadCancelIcon then
  begin
    FDownloadCancelIcon := AValue;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPDownloader.SetDownloaderState(const AValue: TUWPControlState);
begin
  if AValue <> FDownloaderState then
  begin
    FDownloaderState := AValue;
    UpdateColors;
    Invalidate;
  end;
end;

procedure TUWPDownloader.SetDownloaderStyle(const AValue: TUWPDownloaderStyle);
begin
  if AValue <> FDownloaderStyle then
  begin
    FDownloaderStyle := AValue;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPDownloader.SetDownloadPauseIcon(const AValue: string);
begin
  if AValue <> FDownloadPauseIcon then
  begin
    FDownloadPauseIcon := AValue;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPDownloader.SetDownloadRestartIcon(const AValue: string);
begin
  if AValue <> FDownloadRestartIcon then
  begin
    FDownloadRestartIcon := AValue;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPDownloader.SetDownloadStartIcon(const AValue: string);
begin
  if AValue <> FDownloadStartIcon then
  begin
    FDownloadStartIcon := AValue;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPDownloader.SetExtraDetail(const AValue: string);
begin
  if AValue <> FExtraDetail then
  begin
    FExtraDetail := AValue;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPDownloader.SetFontIcon(const AValue: string);
begin
  if AValue <> FFontIcon then
  begin
    FFontIcon := AValue;
    Invalidate;
  end;
end;

procedure TUWPDownloader.SetImageIndex(const AValue: Integer);
begin
  if AValue <> FImageIndex then
  begin
    FImageIndex := AValue;
    Invalidate;
  end;
end;

procedure TUWPDownloader.SetImageKind(const AValue: TUWPImageKind);
begin
  if AValue <> FImageKind then
  begin
    FImageKind := AValue;
    Invalidate;
  end;
end;

procedure TUWPDownloader.SetImages(const AValue: TCustomImageList);
begin
  if AValue <> FImages then
  begin
    FImages := AValue;
    Invalidate;
  end;
end;

procedure TUWPDownloader.SetImageSpace(const AValue: Integer);
begin
  if AValue <> FImageSpace then
  begin
    FImageSpace := AValue;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPDownloader.SetProgressBottom(const AValue: string);
begin
  if AValue <> FProgressBottom then
  begin
    FProgressBottom := AValue;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPDownloader.SetProgressTop(const AValue: string);
begin
  if AValue <> FProgressTop then
  begin
    FProgressTop := AValue;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPDownloader.SetSpacing(const AValue: Integer);
begin
  if AValue <> FSpacing then
  begin
    FSpacing := AValue;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPDownloader.SetStatus(const AValue: string);
begin
  if AValue <> FStatus then
  begin
    FStatus := AValue;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPDownloader.SetTransparent(const AValue: Boolean);
begin
  if AValue <> FTransparent then
  begin
    FTransparent := AValue;
    UpdateColors;
    Invalidate;
  end;
end;

procedure TUWPDownloader.SetValue(const AValue: Byte);
begin
  if AValue <> FValue then
    if AValue <= 100 then
    begin
      FValue := AValue;
      if Assigned(FOnChange) then
        FOnChange(Self);
      UpdateRects;
      Invalidate;
    end;
end;

procedure TUWPDownloader.UpdateColorization(const IncludeChildren: Boolean);
begin
  UpdateColors;
  UpdateRects;
  Invalidate;
end;

procedure TUWPDownloader.UpdateColors;
var
  LCM: TUWPColorizationManager;
  LBackColor: TUWPStateColorSet;
  LAccentColor: TColor;
//  LIsSelected: Boolean;
  LIsDark: Boolean;
begin
  LCM := SelectColorizationManager(Self);
  LIsDark := (LCM <> nil) and (LCM.Colorization = ucDark);
  LAccentColor := SelectAccentColor(LCM, $D77800);
  LBackColor := SelectColorSet(LCM, CustomBackColor, LISTBUTTON_BACK);

  // Disabled
  if not Enabled then
  begin
    if Transparent and (DownloaderState = csNone) then
    begin
      ParentColor := True;
      BackColor := Color;
    end
    else if LIsDark then
      BackColor := $333333
    else
      BackColor := $CCCCCC;
    TextColor := $666666;
    DetailColor := $808080;
    ExtraDetailColor := $808080;
    StatusColor := $808080;
    ProgressTopColor := $666666;
    ProgressBottomColor := $666666;
  end
  // Enabled
  else
  begin
    // Transparent
    if Transparent and (DownloaderState = csNone) then
    begin
      ParentColor := True;
      BackColor := Color;
    end
    else if DownloaderState = csHover then
    begin
      BackColor := $FAFAFA;
    end
    else
    begin
      //BackColor := LBackColor.GetColor(LCM, DownloaderState, LIsSelected);
      BackColor := Color;
    end;

    // Update text color from background
    TextColor := GetTextColorFromBackground(BackColor);
    DetailColor := $808080;
    ExtraDetailColor := $808080;
    StatusColor := $808080;

    // Progress bar fill color
    FillColor := SelectAccentColor(LCM, CustomFillColor);
  end;
end;

procedure TUWPDownloader.UpdateRects;
begin
  case DownloaderStyle of
    dsHorizontal:
    begin
      ImgRect := Rect(0, 0, ImageSpace, Height);
      TextRect := Rect(ImageSpace, 0, Width - Spacing, Height);
      DetailRect := Rect(ImageSpace + (Width - ImageSpace) div 4, 0, Width - Spacing, Height);
      ExtraDetailRect := Rect(ImageSpace + (Width - ImageSpace) div 2, 0, Width - Spacing, Height);
      StatusRect := Rect(ImageSpace + (Width - ImageSpace) div 4 * 3, 0, Width - Spacing, Height);
      DownloadBtnRect := Rect(Width - ImageSpace, 0, Width, Height);
      CancelBtnRect := Rect(Width - 2 * ImageSpace, 0, Width - ImageSpace, Height);
      RestartBtnRect := Rect(Width - 3 * ImageSpace, 0, Width - 2 * ImageSpace, Height);
      FillRect := Rect(Width div 2, (Height - FProgressHeight) div 2 ,
          Width div 2 + Round(Value / 100 * (Width / 2 - 3 * ImageSpace)),
       Height - (Height - FProgressHeight) div 2 );
    end;
    dsVertical:
    begin
      ImgRect := Rect(0, 0, ImageSpace, Height);
      TextRect := Rect(ImageSpace, 0, Width - Spacing, Height div 2);
      DetailRect := Rect(ImageSpace, Height div 2, Width - Spacing, Height);
      FillRect := Rect(0, 0, Round(Value / 100 * Width), Height);
    end;
  end;
end;

procedure TUWPDownloader.WMLButtonDown(var AMsg: TWMLButtonDown);
begin
  if not Enabled then Exit;
  DownloaderState := csPress;
  inherited;
end;

procedure TUWPDownloader.WMLButtonUp(var AMsg: TWMLButtonUp);
//var
//  LMousePos: TPoint;
begin
  if not Enabled then Exit;

//  LMousePos := ScreenToClient(Mouse.CursorPos);
//  if PtInRect(GetClientRect, LMousePos) then
//  begin
//    // Select actions
//
//  end;
  DownloaderState := csHover;
  inherited;
end;

end.
