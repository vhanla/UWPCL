unit UWP.LinkLabel;

interface

uses
  Classes, Windows, Messages, ShellApi, Controls, StdCtrls, Graphics, ExtCtrls,
  UWP.Classes, UWP.ColorManager, UWP.Colors;

type
  TUWPLinkLabel = class(TCustomLinkLabel, IUWPControl)
  private
    FControlState: TUWPControlState;
    FCustomTextColor: TUWPStateColorSet;

    FEnabled: Boolean;
    FOpenLink: Boolean;
    FURL: string;

    FOnOpenURL: TNotifyEvent;

    // Setters
    procedure SetControlState(const AValue: TUWPControlState);
    procedure SetEnabled(const AValue: Boolean); reintroduce;

    // Events for children
    procedure CustomTextColor_OnChange(Sender: TObject);

    // Messages handling
    procedure WMLButtonDown(var AMsg: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure WMLButtonUp(var AMsg: TWMLButtonUp); message WM_LBUTTONUP;

    procedure CMMouseEnter(var AMsg: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var AMsg: TMessage); message CM_MOUSELEAVE;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Interface
    function IsContainer: Boolean;
    procedure UpdateColorization(const IncludeChildren: Boolean);

  published
    property ControlState: TUWPControlState read FControlState write SetControlState default csNone;
    property CustomTextColor: TUWPStateColorSet read FCustomTextColor write FCustomTextColor;

    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property OpenLink: Boolean read FOpenLink write FOpenLink default True;
    property URL: string read FURL write FURL;

    property OnOpenURL: TNotifyEvent read FOnOpenURL write FOnOpenURL;

    // Modify default props
    property Cursor default crHandPoint;

    // Enable props
    property Align;
    property Alignment;
    property Anchors;
    property AutoSize;
    property BevelEdges;
    property BevelInner;
    property BevelKind default bkNone;
    property BevelOuter;
    property Caption;
    property Color nodefault;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    //property Enabled;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Touch;
    property UseVisualStyle;
    property Visible;
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
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
    property OnLinkClick;
  end;

implementation

{ TUWPLinkLabel }

procedure TUWPLinkLabel.CMMouseEnter(var AMsg: TMessage);
begin

end;

procedure TUWPLinkLabel.CMMouseLeave(var AMsg: TMessage);
begin

end;

constructor TUWPLinkLabel.Create(AOwner: TComponent);
begin
  inherited;

end;

procedure TUWPLinkLabel.CustomTextColor_OnChange(Sender: TObject);
begin

end;

destructor TUWPLinkLabel.Destroy;
begin

  inherited;
end;

function TUWPLinkLabel.IsContainer: Boolean;
begin

end;

procedure TUWPLinkLabel.SetControlState(const AValue: TUWPControlState);
begin

end;

procedure TUWPLinkLabel.SetEnabled(const AValue: Boolean);
begin

end;

procedure TUWPLinkLabel.UpdateColorization(const IncludeChildren: Boolean);
begin

end;

procedure TUWPLinkLabel.WMLButtonDown(var AMsg: TWMLButtonDown);
begin

end;

procedure TUWPLinkLabel.WMLButtonUp(var AMsg: TWMLButtonUp);
begin

end;

end.
