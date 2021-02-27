unit UWP_RegisterPackage;

interface

uses
  Classes;

procedure Register;

implementation

uses
  UWP.Form, UWP.Caption, UWP.Slider, UWP.Hotkey, UWP.ListButton,
  UWP.Downloader, UWP.Edit, UWP.Button, UWP.QuickButton, UWP.Text,
  UWP.ScrollBox, UWP.ProgressBar, UWP.Panel, UWP.FluentForm;

procedure Register;
begin
  RegisterComponents('UWP Win32', [
    TUWPCaption,
    TUWPSlider,
    TUWPHotkey,
    TUWPListButton,
    TUWPDownloader,
    TUWPEdit,
    TUWPButton,
    TUWPQuickButton,
    TUWPLabel,
    TUWPScrollBox,
    TUWPProgressBar,
    TUWPPanel,
    TUWPFluentForm
  ]);
end;

end.
