unit UWP.ProgressBar;

interface

uses
  Classes, Types, Messages, Controls, Graphics, Forms,
  UWP.IntAnimation, UWP.Classes, UWP.ColorManager, UWP.Utils, UWP.Colors,
  UWP.Form;

type
  TUWPProgressBar = class(TCustomControl, IUWPControl)
  private
    var FillColor, BackColor: TColor;
    var FillRect, BackRect: TRect;

    FAnitSet: TIntAniSet;
    FCustomFillColor: TColor;
    FCustomBackColor: TUWPColorizationColorSet;

    FValue: Byte;
    FOrientation: TUWPOrientation;

    FOnChange: TNotifyEvent;

    // Internal
    procedure UpdateColors;
    procedure UpdateRects;

    // Setters
    procedure SetValue(const AValue: Byte);
    procedure SetOrientation(const AValue: TUWPOrientation);

    // Events for children
    procedure CustomBackColor_OnChange(Sender: TObject);

  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure ChangeScale(M, D: Integer; DpiChanged: Boolean); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Interface
    function IsContainer: Boolean;
    procedure UpdateColorization(const IncludeChildren: Boolean);

    procedure GoToValue(AValue: Integer);

  published
    property AniSet: TIntAniSet read FAnitSet write FAnitSet;
    property CustomFillColor: TColor read FCustomFillColor write FCustomFillColor default $25B006;
    property CustomBackColor: TUWPColorizationColorSet read FCustomBackColor write FCustomBackColor;

    property Value: Byte read FValue write SetValue default 0;
    property Orientation: TUWPOrientation read FOrientation write SetOrientation default oHorizontal;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    // Modify default props
    property Height default 5;
    property Width default 100;

    // Enable other props
    property Align;
    property Anchors;
    property AutoSize;
    property BiDiMode;
    property Caption;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
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
    // Enable to include events
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

{ TUWPProgressBar }

procedure TUWPProgressBar.ChangeScale(M, D: Integer; DpiChanged: Boolean);
begin
  inherited;
  UpdateRects;
end;

constructor TUWPProgressBar.Create(AOwner: TComponent);
begin
  inherited;
  FValue := 0;
  FOrientation := oHorizontal;
  FCustomFillColor := $25B006;

  FCustomBackColor := TUWPColorizationColorSet.Create;
  FCustomBackColor.OnChange := CustomBackColor_OnChange;
  FCustomBackColor.Assign(PROGRESSBAR_BACK);

  FAnitSet := TIntAniSet.Create;
  FAnitSet.QuickAssign(akOut, afkQuartic, 0, 250, 25);

  // Modify default props
  Width := 100;
  Height := 5;

  UpdateColors;
  UpdateRects;
end;

procedure TUWPProgressBar.CustomBackColor_OnChange(Sender: TObject);
begin
  UpdateColors;
  Invalidate;
end;

destructor TUWPProgressBar.Destroy;
begin
  FAnitSet.Free;
  FCustomBackColor.Free;
  inherited;
end;

procedure TUWPProgressBar.GoToValue(AValue: Integer);
var
  LAni: TIntAni;
begin
  if not Enabled then Exit;

  LAni := TIntAni.Create(FValue, Value - FValue,
    procedure (V: Integer)
    begin
      Self.Value := V;
    end, nil
  );
  LAni.AniSet.Assign(Self.AniSet);
  LAni.Start;
end;

function TUWPProgressBar.IsContainer: Boolean;
begin
  Result := False;
end;

procedure TUWPProgressBar.Paint;
begin
  inherited;

  // Draw background
  Canvas.Brush.Handle := CreateSolidBrushWithAlpha(BackColor, 255);
  Canvas.FillRect(BackRect);

  // Draw round
  Canvas.Brush.Handle := CreateSolidBrushWithAlpha(FillColor, 255);
  Canvas.FillRect(FillRect);
end;

procedure TUWPProgressBar.Resize;
begin
  inherited;
  UpdateRects;
end;

procedure TUWPProgressBar.SetOrientation(const AValue: TUWPOrientation);
begin
  if AValue <> FOrientation then
  begin
    FOrientation := AValue;
    UpdateRects;
    Invalidate;
  end;
end;

procedure TUWPProgressBar.SetValue(const AValue: Byte);
begin
  if AValue <> FValue then
  begin
    if AValue <= 100 then
    begin
      FValue := AValue;
      if Assigned(FOnChange) then
        FOnChange(Self);
      UpdateRects;
      Invalidate;
    end;
  end;
end;

procedure TUWPProgressBar.UpdateColorization(const IncludeChildren: Boolean);
begin
  UpdateColors;
  UpdateRects;
  Invalidate;
end;

procedure TUWPProgressBar.UpdateColors;
var
  LCM: TUWPColorizationManager;
  LBackColor: TUWPColorizationColorSet;
begin
  LCM := SelectColorizationManager(Self);

  FillColor := SelectAccentColor(LCM, CustomFillColor);

  LBackColor := SelectColorSet(LCM, CustomBackColor, PROGRESSBAR_BACK);
  BackColor := LBackColor.GetColor(LCM);
end;

procedure TUWPProgressBar.UpdateRects;
begin
  if FOrientation = oHorizontal then
  begin
    FillRect := Rect(0, 0, Round(Value / 100 * Width), Height);
    BackRect := Rect(FillRect.Right, 0, Width, Height);
  end
  else
  begin
    BackRect := Rect(0, 0, Width, Height - Round(Value / 100 * Height));
    FillRect := Rect(0, BackRect.Bottom, Width, Height);
  end;
end;

end.
