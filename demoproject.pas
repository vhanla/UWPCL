unit demoproject;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, UWP.Form, UWP.Utils, UWP.Classes, Direct2D,
  Vcl.ExtCtrls, UWP.Caption, UWP.Panel, Vcl.Buttons, UWP.Slider,
  Vcl.ComCtrls, Vcl.StdCtrls, UWP.Edit, UWP.Hotkey,
  UWP.ListButton, UWP.ProgressBar, UWP.Downloader, Vcl.WinXPanels, Vcl.WinXCtrls,
  UWP.Button, UWP.QuickButton, UWP.FluentForm;

type
  TForm1 = class(TForm)
    UWPCaption1: TUWPCaption;
    UWPDownloader1: TUWPDownloader;
    UWPDownloader2: TUWPDownloader;
    UWPDownloader3: TUWPDownloader;
    UWPDownloader4: TUWPDownloader;
    UWPDownloader5: TUWPDownloader;
    SaveDialog1: TSaveDialog;
    SplitView1: TSplitView;
    CardPanel1: TCardPanel;
    Card1: TCard;
    UWPEdit1: TUWPEdit;
    UWPButton1: TUWPButton;
    UWPQuickButton1: TUWPQuickButton;
    LinkLabel1: TLinkLabel;
    UWPSlider1: TUWPSlider;
    UWPFluentForm1: TUWPFluentForm;
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure UWPDownloader3Click(Sender: TObject);
    procedure UWPQuickButton1Click(Sender: TObject);
    procedure LinkLabel1LinkClick(Sender: TObject; const Link: string;
      LinkType: TSysLinkType);
    procedure UWPButton1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  ShLwApi;

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
//  BorderStyle := bsNone;
//  Color := clBlack;
//  BorderIcons := [];
//  ShadowOnBorderless := False;
//  FluentEnabled := True;
  // enable ctrl+backspace
  DoubleBuffered := True;
  SHAutoComplete(UWPEdit1.Handle, SHACF_DEFAULT);

end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture;
  PostMessage(Handle, WM_SYSCOMMAND, $F012, 0);
end;

procedure TForm1.LinkLabel1LinkClick(Sender: TObject; const Link: string;
  LinkType: TSysLinkType);
begin
  showmessage(link);
end;

procedure TForm1.UWPButton1Click(Sender: TObject);
begin
  //GetLastActivePopup()
  //Refresh Start Menu
  PostMessage(FindWindow('Shell_TrayWnd', nil),WM_USER+$161, 0, 0);
end;

procedure TForm1.UWPDownloader3Click(Sender: TObject);
begin
  if SaveDialog1.Execute then
  begin
    UWPDownloader3.SavePath := SaveDialog1.FileName;
    UWPDownloader3.DoStartDownload;
  end;
end;

procedure TForm1.UWPQuickButton1Click(Sender: TObject);
begin
  Close;
end;

end.
