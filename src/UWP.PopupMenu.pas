unit UWP.PopupMenu;

interface

uses
  Classes, Types, Windows, Forms, Controls, Menus, Graphics, Messages,
  UWP.IntAnimation,
  UWP.Classes, UWP.ColorManager, UWP.Utils, UWP.Graphics,
  UWP.Form, UWP.ListButton, UWP.Colors;

type
  TIndexNotifyEvent = procedure (Sender: TObject; Index: Integer) of object;

  TUPopupPoint = (ppTopLeft, ppTopRight, ppBottomLeft, ppBottomRight);

  TUPopupMenu = class(TPopupMenu, IUWPControl)
    private
      var BackColor: TColor;

      FAniSet: TIntAniSet;
      FCustomBackColor: TUWPColorizationColorSet;

      FItemWidth: Integer;
      FItemHeight: Integer;
      FTopSpace: Integer;
      FImageKind: TUWPImageKind;

      FOnItemClick: TIndexNotifyEvent;

      //  Child events
      procedure CustomBackColor_OnChange(Sender: TObject);
      procedure PopupForm_OnDeactivate(Sender: TObject);
      procedure PopupItem_OnClick(Sender: TObject);

    public
      constructor Create(aOwner: TComponent); override;
      destructor Destroy; override;

      //  Interface
      function IsContainer: Boolean;
      procedure UpdateColorization(const UpdateChildren: Boolean);

      //  Utils
      procedure Popup(X, Y: Integer); override;
      procedure PopupAtPoint(P: TPoint); overload;
      procedure PopupAtMouse; overload;

      procedure ExtractPackedContent(Input: string; out Icon, Text, Detail: string);

    published
      property AniSet: TIntAniSet read FAniSet write FAniSet;
      property CustomBackColor: TUWPColorizationColorSet read FCustomBackColor write FCustomBackColor;

      property ItemWidth: Integer read FItemWidth write FItemWidth default 200;
      property ItemHeight: Integer read FItemHeight write FItemHeight default 32;
      property TopSpace: Integer read FTopSpace write FTopSpace default 5;
      property ImageKind: TUWPImageKind read FImageKind write FImageKind default ikFontIcon;

      property OnItemClick: TIndexNotifyEvent read FOnItemClick write FOnItemClick;
  end;

implementation

{ TUPopupMenu }

//  INTERFACE

function TUPopupMenu.IsContainer: Boolean;
begin
  Result := true;
end;

procedure TUPopupMenu.UpdateColorization(const UpdateChildren: Boolean);
var
  TM: TUWPColorizationManager;
  _BackColor: TUWPColorizationColorSet;
begin
  //  Update colors
  if (Owner is TForm) and (Owner <> nil) then
    TM := SelectColorizationManager(Owner as TControl)
  else
    TM := nil;

  _BackColor := SelectColorSet(TM, CustomBackColor, POPUP_BACK);
  BackColor := _BackColor.GetColor(TM);

  //  Do not update children
end;

//  CHILD EVENT

procedure TUPopupMenu.CustomBackColor_OnChange(Sender: TObject);
begin
  UpdateColorization(false);
end;

procedure TUPopupMenu.PopupForm_OnDeactivate(Sender: TObject);
var
  Form: TForm;
begin
  if not ((Sender is TForm) and (Sender <> nil)) then exit;
  Form := Sender as TForm;
  Form.Close;
end;

procedure TUPopupMenu.PopupItem_OnClick(Sender: TObject);
begin
  if (Sender is TUWPListButton) and (Assigned(FOnItemClick)) then
    FOnItemClick(Self, (Sender as TUWPListButton).Tag);
end;

//  MAIN CLASS

constructor TUPopupMenu.Create(aOwner: TComponent);
begin
  inherited;

  FItemWidth := 200;
  FItemHeight := 32;
  FTopSpace := 5;
  FImageKind := ikFontIcon;

  FAniSet := TIntAniSet.Create;
  FAniSet.QuickAssign(akOut, afkQuartic, 0, 120, 12);

  FCustomBackColor := TUWPColorizationColorSet.Create;
  FCustomBackColor.OnChange := CustomBackColor_OnChange;
  FCustomBackColor.Assign(POPUP_BACK);
end;

destructor TUPopupMenu.Destroy;
begin
  FAniSet.Free;
  FCustomBackColor.Free;
  inherited;
end;

//  UTILS

procedure TUPopupMenu.ExtractPackedContent(Input: string; out Icon, Text, Detail: string);
var
  SeparatorPos: Integer;
begin
  if Length(Input) = 0 then
    begin
      Icon := '';
      Text := '';
      Detail := '';
    end
  else
    begin
      Icon := Input[1];
      Input := Copy(Input, 2, Length(Input) - 1);
      SeparatorPos := Pos('|', Input);
      if SeparatorPos = 0 then
        begin
          Text := Input;
          Detail := '';
        end
      else
        begin
          Text := Copy(Input, 1, SeparatorPos - 1);
          Detail := Copy(Input, SeparatorPos + 1, Length(Input) - SeparatorPos);
        end;
    end;
end;

procedure TUPopupMenu.Popup(X, Y: Integer);
var
  Form: TUWPForm;
  i, ItemCount: Integer;
  MenuItem: TMenuItem;
  UItem: TUWPListButton;
  Icon, Text, Detail: string;
  Ani: TIntAni;

  DPI: Integer;
  Ratio: Single;
  TotalItemsHeight: Integer;
  Spacing: Integer;
  ItemW: Integer;

  PopupPoint: TUPopupPoint;
begin
  //  Update theme
  UpdateColorization(false);

  //  High DPI
  if Owner is TUWPForm then
    DPI := (Owner as TUWPForm).PPI
  else
    DPI := 96;
  Ratio := DPI / 96;

  //  Getting something
  ItemCount := Self.Items.Count;
  if ItemCount = 0 then exit;

  Spacing := Round(TopSpace * Ratio);
  ItemW := Round(ItemWidth * Ratio);

  //  Create popup form
  Form := TUWPForm.CreateNew(Self);
  Form.OnDeactivate := PopupForm_OnDeactivate;

  //  Theme manager
  if (Owner is TUWPForm) and (Owner <> nil) then
    Form.ColorizationManager.Assign((Owner as TUWPForm).ColorizationManager);

  Form.DoubleBuffered := true;
  Form.BorderStyle := bsToolWindow;
  Form.Color := BackColor;

  Form.Padding.Bottom := Spacing;
  Form.ClientWidth := ItemW;
  Form.ClientHeight := 0;

  //  Find popup point
  TotalItemsHeight := ItemCount * Round(ItemHeight * DPI / 96);

  if X + Form.Width > Screen.WorkAreaWidth then
    //  Left
    begin
      if Y + TotalItemsHeight + 2 * Spacing > Screen.WorkAreaHeight then
        PopupPoint := ppTopLeft
      else
        PopupPoint := ppBottomLeft;
    end
  else
    //  Right
    begin
      if Y + TotalItemsHeight + 2 * Spacing > Screen.WorkAreaHeight then
        PopupPoint := ppTopRight
      else
        PopupPoint := ppBottomRight;
    end;

  //  Modify form padding
  if (PopupPoint = ppBottomLeft) or (PopupPoint = ppBottomRight) then
    Form.Padding.Bottom := Spacing
  else
    Form.Padding.Top := Spacing;

  //  Build items
  for i := 0 to ItemCount - 1 do
    begin
      if (PopupPoint = ppBottomLeft) or (PopupPoint = ppBottomRight) then
        MenuItem := Self.Items[i]
      else
        MenuItem := Self.Items[ItemCount - 1 - i];

      UItem := TUWPListButton.Create(Form);
      UItem.Tag := i;
      UItem.Parent := Form;
      UItem.ParentFont := true;
      UItem.Enabled := MenuItem.Enabled;
      UItem.OnClick := PopupItem_OnClick;

      UItem.Hint := MenuItem.Hint;
      UItem.Images := Self.Images;
      UItem.ImageIndex := MenuItem.ImageIndex;

      ExtractPackedContent(MenuItem.Caption, Icon, Text, Detail);
      UItem.FontIcon := Icon;
      UItem.Caption := Text;
      UItem.Detail := Detail;
      UItem.ImageKind := Self.ImageKind;

      if (PopupPoint = ppBottomLeft) or (PopupPoint = ppBottomRight) then
        UItem.Align := alBottom
      else
        UItem.Align := alTop;
      UItem.Width := ItemWidth;
      UItem.Height := ItemHeight;
      UItem.ShowHint := true;
      UItem.Transparent := true;

      //  Scale item
      UItem.ScaleForPPI(DPI);
      UItem.Font.Height := MulDiv(UItem.Font.Height, DPI, 96);  //  Scaling for text font
    end;

  case PopupPoint of
    ppTopLeft:
      begin
        Form.Left := X - Form.Width;
        Form.Top := Y - TotalItemsHeight - 2 * Spacing;
      end;
    ppTopRight:
      begin
        Form.Left := X;
        Form.Top := Y - TotalItemsHeight - 2 * Spacing;
      end;
    ppBottomLeft:
      begin
        Form.Left := X - Form.Width;
        Form.Top := Y;
      end;
    ppBottomRight:
      begin
        Form.Left := X;
        Form.Top := Y;
      end;
  end;
  Form.Visible := true;

  //  Animation
  Ani := TIntAni.Create(0, TotalItemsHeight + 2 * Spacing,
    procedure (Value: Integer)
    begin
      if (PopupPoint = ppBottomLeft) or (PopupPoint = ppBottomRight) then
        Form.ClientHeight := Value
      else
        begin
          Form.ClientHeight := Value;
          Form.Top := Y - Form.ClientHeight;
        end;
    end, nil);
  Ani.AniSet.Assign(AniSet);
  Ani.Start;
end;

procedure TUPopupMenu.PopupAtMouse;
begin
  Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

procedure TUPopupMenu.PopupAtPoint(P: TPoint);
begin
  Popup(P.X, P.Y);
end;

end.
