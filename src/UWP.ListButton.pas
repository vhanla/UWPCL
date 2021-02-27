unit UWP.ListButton;

interface

uses
  Classes, SysUtils, Types, Messages, Controls, ExtCtrls, ImgList, Graphics, Windows,
  UWP.Classes, UWP.ColorManager, UWP.Colors, UWP.Graphics, UWP.Utils;

type
  TUWPListStyle = (lsRightDetail, lsBottomDetail, lsVertical);

  TUWPSelectMode = (smNone, smSelect, smToggle);

  TUWPListButton = class(TPanel, IUWPControl)
  private
    var BackColor, TextColor, DetailColor: TColor;
    var ImgRect, TextRect, DetailRect: TRect;

    FIconFont: TFont;
    FCustomBackColor: TUWPStateColorSet;

    FButtonState: TUWPControlState;
    FListStyle: TUWPListStyle;

    FImageKind: TUWPImageKind;
    FImages: TCustomImageList;
    FImageIndex: Integer;
    FFontIcon: string;

    FImageSpace: Integer;
    FSpacing: Integer;

    FDetail: string;
    FTransparent: Boolean;

    FSelectMode: TUWPSelectMode;
    FSelected: Boolean;

    // Internal
    procedure UpdateColors;
    procedure UpdateRects;

    // Setters
    procedure SetButtonState(const AValue: TUWPControlState);
    procedure SetListStyle(const AValue: TUWPListStyle);

    procedure SetImageKind(const AValue: TUWPImageKind);
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetImageIndex(const AValue: Integer);
    procedure SetFontIcon(const AValue: string);

    procedure SetImageSpace(const AValue: Integer);
    procedure SetSpacing(const AValue: Integer);

    procedure SetDetail(const AValue: string);
    procedure SetTransparent(const AValue: Boolean);

    procedure SetSelectMode(const AValue: TUWPSelectMode);
    procedure SetSelected(const AValue: Boolean);

    // Getters
    function GetSelected: Boolean;

    // Events to handle children
    procedure CustomBackColor_OnChange(Sender: TObject);

    // Message Handling
    procedure WMLButtonDown(var AMsg: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure WMLButtonUp(var AMsg: TWMLButtonUp); message WM_LBUTTONUP;

    procedure CMMouseEnter(var AMsg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var AMsg: TMessage); message CM_MOUSELEAVE;
    procedure CMEnableChanged(var AMsg: TMessage); message CM_ENABLEDCHANGED;
    procedure CMTextChanged(var AMsg: TMessage); message CM_TEXTCHANGED;

  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure CreateWindowHandle(const AParams: TCreateParams); override;
    procedure ChangeScale(M, D: Integer; ADpiChanged: Boolean); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Loaded; override;

    // Interface
    function IsContainer: Boolean;
    procedure UpdateColorization(const AIncludeChildren: Boolean);

  published
    property IconFont: TFont read FIconFont write FIconFont;
    property CustomBackColor: TUWPStateColorSet read FCustomBackColor write FCustomBackColor;

    property ButtonState: TUWPControlState read FButtonState write SetButtonState default csNone;
    property ListStyle: TUWPListStyle read FListStyle write SetListStyle default lsRightDetail;

    property ImageKind: TUWPImageKind read FImageKind write SetImageKind default ikFontIcon;
    property Images: TCustomImageList read FImages write SetImages;
    property ImageIndex: Integer read FImageIndex write SetImageIndex default -1;
    property FontIcon: string read FFontIcon write SetFontIcon nodefault;

    property ImageSpace: Integer read FImageSpace write SetImageSpace default 40;
    property Spacing: Integer read FSpacing write SetSpacing default 10;

    property Detail: string read FDetail write SetDetail nodefault;
    property Transparent: Boolean read FTransparent write SetTransparent default False;

    property SelectMode: TUWPSelectMode read FSelectMode write SetSelectMode default smNone;
    property Selected: Boolean read GetSelected write SetSelected default False;

    // Modify default props
    property BevelOuter default bvNone;
    property ParentBackground default False;
    property TabStop default True;
    property FullRepaint default False;
  end;

implementation

uses
  UWP.FontIcons;

{ TUWPListButton }

procedure TUWPListButton.ChangeScale(M, D: Integer; ADpiChanged: Boolean);
begin
  inherited;
  FImageSpace := MulDiv(ImageSpace, M, D);
  FSpacing := MulDiv(Spacing, M, D);
  IconFont.Height := MulDiv(IconFont.Height, M, D);
  UpdateRects;
end;

procedure TUWPListButton.CMEnableChanged(var AMsg: TMessage);
begin
  UpdateColors;
  Invalidate;
  inherited;
end;

procedure TUWPListButton.CMMouseEnter(var AMsg: TMessage);
begin
  if not Enabled then Exit;
  ButtonState := csHover;
  inherited;
end;

procedure TUWPListButton.CMMouseLeave(var AMsg: TMessage);
begin
  if not Enabled then Exit;
  ButtonState := csNone;
  inherited;
end;

procedure TUWPListButton.CMTextChanged(var AMsg: TMessage);
begin
  UpdateRects;
  Invalidate;
  inherited;
end;

constructor TUWPListButton.Create(AOwner: TComponent);
begin
  inherited;

  ControlStyle := ControlStyle - [csDoubleClicks];

  FButtonState := csNone;
  FImageKind := ikFontIcon;
  FImageIndex := -1;
  FFontIcon := UF_BACK;
  FListStyle := lsRightDetail;
  FImageSpace := 40;
  FSpacing := 10;
  FDetail := 'Detail';
  FTransparent := False;

  FSelectMode := smNone;
  FSelected := False;

  FIconFont := TFont.Create;
  IconFont.Name := 'Segoe MDL2 Assets';
  IconFont.Size := 12;

  FCustomBackColor := TUWPStateColorSet.Create;
  FCustomBackColor.OnChange := CustomBackColor_OnChange;
  FCustomBackColor.Assign(LISTBUTTON_BACK);

  // Modify default props
  BevelOuter := bvNone;
  ParentBackground := False;
  TabStop := True;
  FullRepaint := False;
end;

procedure TUWPListButton.CreateWindowHandle(const AParams: TCreateParams);
begin
  inherited;
  UpdateColors;
  UpdateRects;
end;

procedure TUWPListButton.CustomBackColor_OnChange(Sender: TObject);
begin
  UpdateColors;
  Invalidate;
end;

destructor TUWPListButton.Destroy;
begin
  FIconFont.Free;
  FCustomBackColor.Free;
  inherited;
end;

function TUWPListButton.GetSelected: Boolean;
begin
  case SelectMode of
    smNone:
      Result := False;
    smSelect:
      Result := FSelected;
    smToggle:
      Result := FSelected;
    else
      Result := False;
  end;
end;

function TUWPListButton.IsContainer: Boolean;
begin
  Result := False;
end;

procedure TUWPListButton.Loaded;
begin
  inherited;
  UpdateColors;
  UpdateRects;
end;

procedure TUWPListButton.Paint;
var
  LImgX, LImgY: Integer;
begin
  //  inherited;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Handle := CreateSolidBrushWithAlpha(BackColor, 255);
  Canvas.FillRect(Rect(0, 0, Width, Height));

  Canvas.Brush.Style := bsClear;

  // Draw Image
  if ImageKind = ikFontIcon then
  begin
    // Set up icon font
    Canvas.Font.Assign(IconFont);
    Canvas.Font.Color := TextColor;

    // Draw font icon
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
  case ListStyle of
    lsRightDetail, lsBottomDetail:
      DrawTextRect(Canvas, taLeftJustify, taVerticalCenter, TextRect, Caption, False);
    lsVertical:
      DrawTextRect(Canvas, taCenter, taAlignTop, TextRect, Caption, False);
  end;

  // Draw Detail text
  Canvas.Font.Color := DetailColor;
  case ListStyle of
    lsRightDetail:
      DrawTextRect(Canvas, taRightJustify, taVerticalCenter, DetailRect, Detail, False);
    lsBottomDetail:
      DrawTextRect(Canvas, taLeftJustify, taAlignTop, DetailRect, Detail, False);
    lsVertical:
      DrawTextRect(Canvas, taCenter, taAlignBottom, DetailRect, Detail, False);
  end;
end;

procedure TUWPListButton.Resize;
begin
  inherited;
  UpdateRects;
end;

procedure TUWPListButton.SetButtonState(const AValue: TUWPControlState);
begin
  if AValue <> FButtonState then
  begin
    FButtonState := AValue;
    UpdateColors;
    Invalidate;
  end;
end;

procedure TUWPListButton.SetDetail(const AValue: string);
begin
  if AValue <> FDetail then
  begin
    FDetail := AValue;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPListButton.SetFontIcon(const AValue: string);
begin
  if AValue <> FFontIcon then
  begin
    FFontIcon := AValue;
    Invalidate;
  end;
end;

procedure TUWPListButton.SetImageIndex(const AValue: Integer);
begin
  if AValue <> FImageIndex then
  begin
    FImageIndex := AValue;
    Invalidate;
  end;
end;

procedure TUWPListButton.SetImageKind(const AValue: TUWPImageKind);
begin
  if AValue <> FImageKind then
  begin
    FImageKind := AValue;
    Invalidate;
  end;
end;

procedure TUWPListButton.SetImages(const AValue: TCustomImageList);
begin
  if AValue <> FImages then
  begin
    FImages := AValue;
    Invalidate;
  end;
end;

procedure TUWPListButton.SetImageSpace(const AValue: Integer);
begin
  if AValue <> FImageSpace then
  begin
    FImageSpace := AValue;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPListButton.SetListStyle(const AValue: TUWPListStyle);
begin
  if AValue <> FListStyle then
  begin
    FListStyle := AValue;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPListButton.SetSelected(const AValue: Boolean);
var
  I: Integer;
  LItem: TUWPListButton;
begin
  if AValue <> FSelected then
  begin
    FSelected := AValue;

    if AValue and (FSelectMode = smSelect) then
    begin
      for I := 0 to Parent.ControlCount - 1 do
      begin
        if Parent.Controls[I] is TUWPListButton then
        begin
          LItem := TUWPListButton(Parent.Controls[I]);
          if LItem <> Self then
            LItem.Selected := False;
        end;
      end;
    end;

    UpdateColors;
    Invalidate;
  end;
end;

procedure TUWPListButton.SetSelectMode(const AValue: TUWPSelectMode);
begin
  if AValue <> FSelectMode then
  begin
    FSelectMode := AValue;
    UpdateColors;
    Invalidate;
  end;
end;

procedure TUWPListButton.SetSpacing(const AValue: Integer);
begin
  if AValue <> FSpacing then
  begin
    FSpacing := AValue;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPListButton.SetTransparent(const AValue: Boolean);
begin
  if AValue <> FTransparent then
  begin
    FTransparent := AValue;
    UpdateColors;
    Invalidate;
  end;
end;

procedure TUWPListButton.UpdateColorization(const AIncludeChildren: Boolean);
begin
  UpdateColors;
  UpdateRects;
  Invalidate;
end;

procedure TUWPListButton.UpdateColors;
var
  LCM: TUWPColorizationManager;
  LBackColor: TUWPStateColorSet;
  LAccentColor: TColor;
  LIsSelected: Boolean;
  LIsDark: Boolean;
begin
  // Preparing
  LCM := SelectColorizationManager(Self);
  LIsDark := (LCM <> nil) and (LCM.Colorization = ucDark);
  LAccentColor := SelectAccentColor(LCM, $D77800);
  LBackColor := SelectColorSet(LCM, CustomBackColor, LISTBUTTON_BACK);

  // Disabled
  if not Enabled then
  begin
    if Transparent and (ButtonState = csNone) then
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
  end
  // Enabled
  else
  begin
    LIsSelected := Selected;

    // Selected
    if LIsSelected then
      BackColor := ColorChangeLightness(LAccentColor, LBackColor.GetColor(LCM, ButtonState, LIsSelected))
    // Transparent
    else if Transparent and (ButtonState = csNone) then
    begin
      ParentColor := True;
      BackColor := Color;
    end
    // Not Selected
    else
      BackColor := LBackColor.GetColor(LCM, ButtonState, LIsSelected);

    // Update text color from background
    TextColor := GetTextColorFromBackground(BackColor);
    if not LIsSelected then
      DetailColor := $808080
    else
      DetailColor := $D0D0D0; // Detail on background color
  end;
end;

procedure TUWPListButton.UpdateRects;
begin
  case ListStyle of
    lsRightDetail:
    begin
      ImgRect := Rect(0, 0, ImageSpace, Height);
      TextRect := Rect(ImageSpace, 0, Width - Spacing, Height);
      DetailRect := Rect(ImageSpace, 0, Width - Spacing, Height);
    end;

    lsBottomDetail:
    begin
      ImgRect := Rect(0, 0, ImageSpace, Height);
      TextRect := Rect(ImageSpace, 0, Width - Spacing, Height div 2);
      DetailRect := Rect(ImageSpace, Height div 2, Width - Spacing, Height);
    end;

    lsVertical:
    begin
      ImgRect := Rect(0, 0, Width, ImageSpace);
      TextRect := Rect(0, ImageSpace, Width, Height - Spacing);
      DetailRect := Rect(0, ImageSpace, Width, Height - Spacing);
    end;
  end;
end;

procedure TUWPListButton.WMLButtonDown(var AMsg: TWMLButtonDown);
begin
  if not Enabled then Exit;
  ButtonState := csPress;
  inherited;
end;

procedure TUWPListButton.WMLButtonUp(var AMsg: TWMLButtonUp);
var
  LMousePos: TPoint;
begin
  if not Enabled then Exit;

  LMousePos := ScreenToClient(Mouse.CursorPos);
  if PtInRect(GetClientRect, LMousePos) then
  begin
    // Select actions
    case SelectMode of
      smNone:
        Selected := False;
      smSelect:
        Selected := True;
      smToggle:
        Selected := not Selected;
    end;
  end;

  ButtonState := csHover;
  inherited;
end;

end.
