unit UWP.FluentForm;

interface

uses
  System.SysUtils, System.Classes, Vcl.Forms, Winapi.Windows, Winapi.Messages,
  Vcl.ExtCtrls;

type

  TBoundCaption = class(TCustomPanel)
  private
    function GetTop: Integer;
    function GetLeft: Integer;
    function GetWidth: Integer;
    function GetHeight: Integer;
    procedure SetHeight(const Value: Integer);
    procedure SetWidth(const Value: Integer);
  protected
//    procedure AdjustBounds; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property BiDiMode;
    property Caption;
    property Color;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Font;
    property Height: Integer read GetHeight write SetHeight;
    property Left: Integer read GetLeft;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Top: Integer read GetTop;
    property Touch;
//    property Transparent;
//    property Layout;
//    property WordWrap;
    property Width: Integer read GetWidth write SetWidth;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnGesture;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
  end;

  TUWPFluentForm = class(TComponent)
  private
    fCaption: TBoundCaption;

    fForm: TForm;
    fOldTWndMethod: TWndMethod;
    fBorderLess: Boolean;

    function GetNCBorderSize: Integer;

    procedure WMCreate(var AMsg: TMessage);
    procedure WMDestroy(var AMsg: TMessage);
    procedure WMNCCalcSize(var AMsg: TMessage);
    procedure WndProc(var AMsg: TMessage);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
//    procedure SetBounds(ALeft: Integer; ATop: Integer; AWidth: Integer; AHeight: Integer); override;
//    procedure ScaleForPPI(NewPPI: Integer); override;
  published
    property Borderless: boolean read fBorderLess write fBorderLess;
  end;
implementation

{ TBoundCaption }

constructor TBoundCaption.Create(AOwner: TComponent);
begin
  inherited;

end;

function TBoundCaption.GetHeight: Integer;
begin

end;

function TBoundCaption.GetLeft: Integer;
begin

end;

function TBoundCaption.GetTop: Integer;
begin

end;

function TBoundCaption.GetWidth: Integer;
begin

end;

procedure TBoundCaption.SetHeight(const Value: Integer);
begin

end;

procedure TBoundCaption.SetWidth(const Value: Integer);
begin

end;

{ TFluentForm }

constructor TUWPFluentForm.Create(AOwner: TComponent);
var
  I: Integer;
begin

  if not (AOwner is TForm) then
    raise EInvalidCast.Create('TFluentForm can only be on TForm');

  with AOwner do
    for I := 0 to ComponentCount - 1 do
      if (Components[I] is TUWPFluentForm) and
        (Components[I] <> Self) then
          raise EComponentError.Create('Only one TFluentForm Component is allowed');

  inherited Create(AOwner);

  fForm := TForm(AOwner);
  fBorderLess := False;
  fOldTWndMethod := fForm.WindowProc;
  fForm.WindowProc := WndProc;

  if not Assigned(fCaption) then
  begin
    fCaption := TBoundCaption.Create(Self);
    fCaption.FreeNotification(Self);
  end;
end;

destructor TUWPFluentForm.Destroy;
begin
  fForm.WindowProc := fOldTWndMethod;
  inherited Destroy;
end;


function TUWPFluentForm.GetNCBorderSize: Integer;
begin
  Result := 0;

  case fForm.BorderStyle of
    bsSingle:
      Result := GetSystemMetrics(SM_CYFIXEDFRAME);

    bsDialog, bsToolWindow:
      Result := GetSystemMetrics(SM_CYDLGFRAME);

    bsSizeable, bsSizeToolWin:
      Result := GetSystemMetrics(SM_CYSIZEFRAME) +
                GetSystemMetrics(SM_CXPADDEDBORDER);
  end;
end;

//procedure TUWPFluentForm.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
//begin
//  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
//
//  if fCaption = nil then Exit;
//
//  fCaption.Alignment := alTop;
//end;

procedure TUWPFluentForm.WMCreate(var AMsg: TMessage);
begin
  fOldTWndMethod(AMsg);

end;

procedure TUWPFluentForm.WMDestroy(var AMsg: TMessage);
begin
  fOldTWndMethod(AMsg);
end;

procedure TUWPFluentForm.WMNCCalcSize(var AMsg: TMessage);
var
  LCaptionBarHeight: Integer;
begin
//  if Borderless then AMsg.Msg := WM_NULL
//  else
//    fOldTWndMethod(AMsg);

  if not Borderless then Exit;

  if fForm.BorderStyle = bsNone then Exit;

  LCaptionBarHeight := GetSystemMetrics(SM_CYCAPTION);

  if fForm.WindowState = wsNormal then
    Inc(LCaptionBarHeight, GetNCBorderSize);

  Dec(TWMNCCalcSize(AMsg).CalcSize_Params.rgrc[0].Top, LCaptionBarHeight);

end;

procedure TUWPFluentForm.WndProc(var AMsg: TMessage);
begin
  if (csDesigning in ComponentState) then fOldTWndMethod(AMsg)
  else
  begin
    case AMsg.Msg of
      WM_CREATE: WMCreate(AMsg);
      WM_DESTROY: WMDestroy(AMsg);
      WM_NCCALCSIZE: WMNCCalcSize(AMsg);
    else fOldTWndMethod(AMsg);
    end;
  end;
end;

end.
