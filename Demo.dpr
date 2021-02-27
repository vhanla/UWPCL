program Demo;

{$R *.dres}

uses
  Fastmm4,
  Vcl.Forms,
  demoproject in 'demoproject.pas' {Form1},
  UWP_RegisterPackage in 'src\UWP_RegisterPackage.pas',
  UWP.Utils in 'src\UWP.Utils.pas',
  UWP.Types in 'src\UWP.Types.pas',
  UWP.SystemSettings in 'src\UWP.SystemSettings.pas',
  UWP.Form in 'src\UWP.Form.pas',
  UWP.Colors in 'src\UWP.Colors.pas',
  UWP.ColorManager in 'src\UWP.ColorManager.pas',
  UWP.Classes in 'src\UWP.Classes.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
