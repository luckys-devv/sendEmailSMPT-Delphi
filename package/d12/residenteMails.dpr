program residenteMails;

uses
  System.StartUpCopy,
  FMX.Forms,
  UMain in '..\..\source\UMain.pas' {FresidenteMails};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFresidenteMails, FresidenteMails);
  Application.Run;
end.
