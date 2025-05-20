unit UMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  RegularExpressions,
  FMX.Objects, FMX.Edit, FMX.Controls.Presentation, FMX.Layouts,
  IdAttachmentFile, IdSMTPServer, IdSMTP, IdSMTPRelay, IdReplySMTP, IdMessage,
  IdStack,
  IdText, IdSSLOpenSSL, IdExplicitTLSClientServerBase;

type
  TFresidenteMails = class(TForm)
    Layout1: TLayout;
    Layout5: TLayout;
    Circle3: TCircle;
    Layout2: TLayout;
    Layout4: TLayout;
    Circle2: TCircle;
    Layout3: TLayout;
    Label1: TLabel;
    edtTo: TEdit;
    edtSubject: TEdit;
    Rectangle1: TRectangle;
    btnAceptar: TSpeedButton;
    edtMessage: TEdit;
    procedure btnAceptarClick(Sender: TObject);
    procedure edtToKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure edtSubjectKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure edtMessageKeyDown(Sender: TObject; var Key: Word;
      var KeyChar: WideChar; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    procedure sendMail(AMailDestino, ASubject, AMessage: String);
    procedure GrabarLogMail(ADato, ACodeError, AMsgError,
      ANombreCarpeta: String);
    function validarMail(AMail: String): Boolean;
  public
    { Public declarations }
  end;

var
  FresidenteMails: TFresidenteMails;

implementation

{$R *.fmx}
{ TForm1 }

procedure TFresidenteMails.btnAceptarClick(Sender: TObject);
var
  vMail: String;
  vSubject: String;
  vMessage: String;
begin
  { Validaciones }
  vMail := Trim(edtTo.Text);
  if not validarMail(vMail) then
  begin
    ShowMessage('Formato de Correo No Valido!');
    Exit;
  end;

  vSubject := Trim(edtSubject.Text);
  if vSubject.Length <= 0 then
  begin
    ShowMessage('Debe ingresar un asunto valido!');
    Exit;
  end;

  vMessage := Trim(edtMessage.Text);
  if vMessage.Length <= 0 then
  begin
    ShowMessage('Debe ingresar algo en el mensaje');
    Exit;
  end;

  { Mandar el mail }
  sendMail(vMail, vSubject, vMessage);
  ShowMessage('Enviado');
end;

procedure TFresidenteMails.sendMail(AMailDestino, ASubject, AMessage: String);
var
  vSMTP: TIdSMTP; { TIdSMTP --> Servidor de Google }
  vMessage: TIdMessage; { TIdMessage --> Mensaje }
  vLSocketSSL: TIdSSLIOHandlerSocketOpenSSL;
  { TIdSSLIOHandlerSocketOpenSSL --> Seguridad }
begin

  TThread.CreateAnonymousThread(
    procedure()
    begin

      try
        vSMTP := TIdSMTP.Create(nil);
        vMessage := TIdMessage.Create(nil);
        vLSocketSSL := TIdSSLIOHandlerSocketOpenSSL.Create(nil);

        try

          { ================--------CONFIGURACION--------================ }
          With vLSocketSSL Do
          begin
            SSLOptions.Mode := sslmClient;
            SSLOptions.Method := sslvTLSv1_2; { google ya va por 1_3 }
            Host := 'smtp.gmail.com';
            Port := 587;
          end;

          With vSMTP Do
          begin
            IOHandler := vLSocketSSL;
            Host := 'smtp.gmail.com';
            Port := 587;
            AuthType := satDefault;
            Username := ''; // AQUI DEBES COLOCAR TU MAIL VERIFICADO
            password := ''; // AQUI LA APIKEY QUE TE DA GMAIL DE ESE MAIL
            UseTLS := utUseExplicitTLS;
          end;

          With vMessage Do
          begin
            ContentType := 'text/plain';
            CharSet := 'UTF-8';
            Encoding := meMIME;
            From.Address := ''; // AQUI DEBES COLOCAR TU MAIL VERIFICADO
            From.name := 'No Reply'; // Nombre del emisor que manda el mail
            Recipients.Clear;
            Recipients.Add.Address := AMailDestino;
            Subject := ASubject;
            Body.Clear;
            Body.Add(AMessage);
          end;

          vSMTP.Connect;
          vSMTP.Send(vMessage);

          if vSMTP.Connected then
            vSMTP.Disconnect;

        finally
          vSMTP.Free;
          vMessage.Free;
          vLSocketSSL.Free;
        end;
      except
        On E: EIdSMTPReplyError Do
        begin
          case E.ErrorCode of
            421 .. 455:
              begin
                GrabarLogMail(AMailDestino, E.ErrorCode.ToString, E.Message,
                  'Error 421-455');
              end;

            500 .. 555:
              begin

                if vSMTP.Connected then
                  vSMTP.Disconnect;

                GrabarLogMail(AMailDestino, E.ErrorCode.ToString, E.Message,
                  'Error 550-555');
              end;
          end;
        end;

        On E: EIdSocketError Do
        begin
          GrabarLogMail(AMailDestino, '-', E.Message, 'MailSocketError');
        end;

        On E: EFOpenError Do
        begin
          GrabarLogMail(AMailDestino, '-', E.Message, 'MailOpenError');
        end;

        On E: Exception Do
        begin
          GrabarLogMail(AMailDestino, '-', E.Message, 'Error Exception');
        end;
      end;

    end).Start;

end;

function TFresidenteMails.validarMail(AMail: String): Boolean;
var
  Regex: TRegEx;
begin
  Regex := TRegEx.Create('^[^\s@]+@[^\s@]+\.[^\s@]+$');
  result := Regex.IsMatch(AMail);
end;

procedure TFresidenteMails.edtMessageKeyDown(Sender: TObject; var Key: Word;
var KeyChar: WideChar; Shift: TShiftState);
begin
  if Key = vkReturn then
    btnAceptar.SetFocus;
end;

procedure TFresidenteMails.edtSubjectKeyDown(Sender: TObject; var Key: Word;
var KeyChar: WideChar; Shift: TShiftState);
begin
  if Key = vkReturn then
    edtMessage.SetFocus;
end;

procedure TFresidenteMails.edtToKeyDown(Sender: TObject; var Key: Word;
var KeyChar: WideChar; Shift: TShiftState);
begin
  if Key = vkReturn then
    edtSubject.SetFocus;
end;

procedure TFresidenteMails.FormShow(Sender: TObject);
begin
  edtTo.SetFocus;
end;

procedure TFresidenteMails.GrabarLogMail(ADato, ACodeError, AMsgError,
  ANombreCarpeta: String);
var
  vFile: TextFile;
  vNombre: String;
begin

  { Creamos carpeta con el nombre que le pasemos en el prc }
  if not DirectoryExists(GetCurrentDir + '\Log') then
    CreateDir(GetCurrentDir + '\Log');

  if not DirectoryExists(GetCurrentDir + '\Log\' + ANombreCarpeta) then
    CreateDir(GetCurrentDir + '\Log\' + ANombreCarpeta);

  { Guardamos el nombre del archivo }
  vNombre := GetCurrentDir + '\Log\' + ANombreCarpeta + '\' +
    FormatDateTime('YYYYMMDDHH', now) + '.log';

  { Asignamos el archivo }
  AssignFile(vFile, vNombre);

  try

    if (FileExists(vNombre)) then
      Append(vFile)
    else
      ReWrite(vFile);

    Writeln(vFile, '[' + DateTimeToStr(now) + '] ' + ADato + ' -- ' +
      'Nro de Error: ' + ACodeError + ' -- ' + AMsgError);

  finally
    CloseFile(vFile);

  end;

end;

end.
