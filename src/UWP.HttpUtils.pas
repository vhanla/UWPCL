unit UWP.HttpUtils;

interface

uses
  Classes, Windows, Messages, SysUtils, Types,
  System.Net.HttpClient, zlib, System.Generics.Collections, System.Generics.Defaults;

type
  TUWPDownload = class;

  TUWPHttpMethod = (hmGet, hmPost, hmPut, hmDelete, hmOptions, hmHead);

  TUWPDownloadFinishedEvent = procedure(const Sender: TUWPDownload; var FreeSender: Boolean) of Object;
  TUrlReadEvent = function(const Url: string; out MimeType: string): TStream of object;
  TUrlWriteEvent = function(const Url: string): TStream of object;

  TUWPDownloadStatus = (dsNotStarted, dsDownloading, dsError, dsSuccess);

  TStreamOption = (soForceMemoryStream, soGzip);
  TStreamOptions = set of TStreamOption;

  TUrlAsynchronousReaderClass = class of TUrlAsynchronousReader;

  TRegisteredProtocol = class
    Protocol: string;
    ReadEvent: TUrlReadEvent;
    WriteEvent: TUrlWriteEvent;
    AsynchronousReader: TUrlAsynchronousReaderClass;
  end;

  TRegisteredProtocols = class(TList<TRegisteredProtocol>)
    function Find(const Protocol: string): TRegisteredProtocol;

    procedure Add(const Protocol: string;
    const ReadEvent: TUrlReadEvent;
    const WriteEvent: TUrlWriteEvent;
    const AsynchronousReader: TUrlAsynchronousReaderClass); reintroduce;
  end;

  TUrlAsynchronousReader = class
  public
    Url: string;
    ForceSynchronous: Boolean;
    HttpMethod: TUWPHttpMethod;
    HttpPostData, HttpHeadersKeys, HttpHeadersValues: TStrings;

    Status: TUWPDownloadStatus;
    DownloadedBytes, TotalBytes: Int64;
    Contents: TStream;
    ErrorMessage: string;
    MimeType: String;
    HttpResponseCode: Integer;
    HttpResponseHeaders: TStrings;

    procedure Start; virtual;
    procedure Update; virtual;
  end;

  TUWPDownload = class(TComponent)
  strict private
    FUrl: string;
    FHttpMethod: TUWPHttpMethod;
    FOnFinish: TUWPDownloadFinishedEvent;
    FStatus: TUWPDownloadStatus;
    FErrorMessage: string;
    FContents: TStream;
    FOwnsContents: Boolean;
    FOptions: TStreamOptions;
    FTotalBytes, FDownloadedBytes: Int64;
    FMimeType: string;
    Reader: TUrlAsynchronousReader;
    UpdateInitialized: Boolean;
    FHttpPostData: TStringList;
    FHttpHeadersKeys, FHttpHeadersValues: TStringList;
    FHttpResponseCode: Integer;
    FHttpResponseHeaders: TStrings;
    procedure SetUrl(const AValue: string);
    procedure SetHttpMethod(const AValue: TUWPHttpMethod);
    procedure SetOnFinish(const AValue: TUWPDownloadFinishedEvent);
    procedure SetOptions(const AValue: TStreamOptions);
    procedure ReleaseContents;
    procedure SetContentsApplyOptions(UnderlyingStream: TStream);
    procedure Update(Sender: TObject);
  private
    ForceSynchronous: Boolean;
  protected
    procedure DoFinish; virtual;
  public
    destructor Destroy; override;

    procedure Start;

    property Url: string read FUrl write SetUrl;
    property Options: TStreamOptions read FOptions write SetOptions;
    property HttpMethod: TUWPHttpMethod read FHttpMethod write SetHttpMethod default hmGet;
    property OnFinish: TUWPDownloadFinishedEvent read FOnFinish write SetOnFinish;
    property Status: TUWPDownloadStatus read FStatus;

    procedure WaitForFinish;

    property ErrorMessage: string read FErrorMessage;
    property Contents: TStream read FContents;
    property OwnsContents: boolean read FOwnsContents write FOwnsContents;
    property DownloadedBytes: Int64 read FDownloadedBytes;
    property TotalBytes: Int64 read FTotalBytes;
    property MimeType: string read FMimeType;

    function HttpPostData: TStrings;
    function PostData: TStrings; deprecated 'use HttpPostData';
    procedure HttpHeader(const AKey, AValue: string);
    procedure AddHeader(const AKey, AValue: string); deprecated 'use HttpHeader';

    property HttpResponseCode: Integer read FHttpResponseCode;
    property HttpResponseHeaders: TStrings read FHttpResponseHeaders;

  end;

implementation

function SameMethods(const AMethod1, AMethod2: TMethod): boolean;
begin
  Result := (AMethod1.Code = AMethod2.Code) and
            (AMethod1.Data = AMethod2.Data);
end;

{ TUWPDownload }

procedure TUWPDownload.AddHeader(const AKey, AValue: string);
begin
  HttpHeader(AKey, AValue);
end;

destructor TUWPDownload.Destroy;
begin
  ReleaseContents;
  if Reader <> nil then
  begin
    FreeAndNil(Reader.Contents); // Reader doesn't own Contents, so we need to take care of it
    FreeAndNil(Reader);
  end;

  if UpdateInitialized then
  begin
    //ApplicationProperties.OnUpdate.Remove(Update);
    UpdateInitialized := False;
  end;
  FreeAndNil(FHttpPostData);
  FreeAndNil(FHttpResponseHeaders);
  FreeAndNil(FHttpHeadersKeys);
  FreeAndNil(FHttpHeadersValues);

  inherited;
end;

procedure TUWPDownload.DoFinish;
var
  LFreeSender: Boolean;
begin
  if Assigned(OnFinish) then
  begin
    LFreeSender := False;
    OnFinish(Self, LFreeSender);
    if LFreeSender then
      Self.Destroy;
  end;
end;

procedure TUWPDownload.HttpHeader(const AKey, AValue: string);
begin
  if FHttpHeadersKeys = nil then
    FHttpHeadersKeys := TStringList.Create;
  if FHttpHeadersValues = nil then
    FHttpHeadersValues := TStringList.Create;
  FHttpHeadersKeys.Append(AKey);
  FHttpHeadersValues.Append(AValue);
  Assert(FHttpHeadersKeys.Count = FHttpHeadersValues.Count);
end;

function TUWPDownload.HttpPostData: TStrings;
begin
  if FHttpPostData = nil then
    FHttpPostData := TStringList.Create;
  Result := FHttpPostData;
end;

function TUWPDownload.PostData: TStrings;
begin
  Result := HttpPostData;
end;

procedure TUWPDownload.ReleaseContents;
begin
  if OwnsContents then
    FreeAndNil(FContents)
  else
    FContents := nil;
end;

procedure TUWPDownload.SetContentsApplyOptions(UnderlyingStream: TStream);
  function CreateMemoryStream(var Stream: TStream): TMemoryStream; overload;
  begin
    Result := TMemoryStream.Create;
    try
      Result.LoadFromStream(Stream);
      FreeAndNil(Stream);
      Result.Position := 0;
    except
      FreeAndNil(Result); raise;
    end;
  end;
  function ReadGzipped(var Stream: TStream; const ForceMemoryStream: Boolean): TStream;
  var
    NewResult: TMemoryStream;
    DecompressionStream: TDecompressionStream;
  begin
    Result := TDecompressionStream.Create(Stream, 15 + 16); // 31 bit wide window = gzip only mode
    try
      Stream := nil;

      if ForceMemoryStream then
      begin
        NewResult := TMemoryStream.Create;

        Result := NewResult;
      end;
    except
      FreeAndNil(Result); raise;
    end;

  end;
begin
  // unpack gzip
  if soGzip in Options then
    FContents := ReadGzipped(UnderlyingStream, soForceMemoryStream in Options)
  else
  if soForceMemoryStream in Options then
    FContents := CreateMemoryStream(UnderlyingStream)
  else
    FContents := UnderlyingStream;

end;

procedure TUWPDownload.SetHttpMethod(const AValue: TUWPHttpMethod);
begin
  if FHttpMethod <> AValue then
  begin
    if Status = dsDownloading then
      raise Exception.Create('Cannot change HTTP method when downloading');
    FHttpMethod := AValue;
  end;
end;

procedure TUWPDownload.SetOnFinish(const AValue: TUWPDownloadFinishedEvent);
begin
  if not SameMethods(TMethod(FOnFinish), TMethod(AValue)) then
  begin
    if Status = dsDownloading then
      raise Exception.Create('Cannot change OnFinish when downloading, you have to set it before Start to be realiable');
    FOnFinish := AValue;
  end;
end;

procedure TUWPDownload.SetOptions(const AValue: TStreamOptions);
begin
  if FOptions <> AValue then
  begin
    if Status = dsDownloading then
      raise Exception.Create('Cannot change Options when downloading');
    FOptions := AValue;
  end;
end;

procedure TUWPDownload.SetUrl(const AValue: string);
begin
  if FUrl <> AValue then
  begin
    if Status = dsDownloading then
      raise Exception.Create('Cannot change URL when downloading');
    FUrl := AValue;
  end;
end;

procedure TUWPDownload.Start;
  // Reset properties that describe the download result.
  procedure ClearPreviousDownload;
  begin
    ReleaseContents;
    if Reader <> nil then
    begin
      FreeAndNil(Reader.Contents); // Reader doesn't own Contents, so we need to take care of it.
      FreeAndNil(Reader);
    end;
    FErrorMessage := '';
    FMimeType := '';
    FTotalBytes := -1;
    FDownloadedBytes := 0;
    FStatus := dsDownloading;
  end;

  procedure SynchronousRead(const ReadEvent: TUrlReadEvent; const RealUrl: string);
  var
    Size: Int64;
  begin
    try
      SetContentsApplyOptions(ReadEvent(RealUrl, FMimeType));
      FStatus := dsSuccess;

      // determine FTotalBytes, FDownloadBytes from stream size
      try
        Size := FContents.Size;
        FTotalBytes := Size;
        FDownloadedBytes := Size;
      except
        on E: TObject do
        begin
          FTotalBytes := -1;
          FDownloadedBytes := 0;
        end;
      end;
    except
      on E: TObject do
      begin
        FStatus := dsError;
        FErrorMessage := Format('Error when downloading "%s": ', [Url]);
      end;
    end;
    DoFinish;
  end;
var
  P, RealUrl: string;
  RegisteredProtocol: TRegisteredProtocol;
begin
  ClearPreviousDownload;

  P := Url;

  if not UpdateInitialized then
  begin
    //todo applicationproperties
    UpdateInitialized := True;
  end;

  RealUrl := Url;

  //#TODO fix this
  //RegisteredProtocol := RegisteredProtocols.Find(P);
  begin
    //if RegisteredProtocol.AsynchronousReader <> nil
//    https://github.com/castle-engine/castle-engine/blob/c52179f7817b1e4aff13913b2c414589108e75e4/src/files/castledownload_asynchronous.inc
//https://github.com/castle-engine/castle-engine/blob/32d46e4a5158e53d6eecfc42585a83ebc2966946/src/files/castledownload_register.inc
  end;
end;

procedure TUWPDownload.Update(Sender: TObject);
begin
  if Status = dsDownloading then
  begin
    Assert(Reader <> nil);

    Reader.Update;

    Assert(Reader.Status <> dsNotStarted);
    FStatus := Reader.Status;
    FDownloadedBytes := Reader.DownloadedBytes;
    FTotalBytes := Reader.TotalBytes;
    FMimeType := Reader.MimeType;

    if FStatus in [dsError, dsSuccess] then
    begin
      // copy stuff from Reader
      if FStatus = dsSuccess then
        Assert(Reader.Contents <> nil); // in this case, Reader.Contents is obligatory

      if Reader.Contents <> nil then // in this case, Reader.Contents is optional
      begin
        SetContentsApplyOptions(Reader.Contents);
        Reader.Contents := nil; // not valid anymore, SetContentsApplyOptions took ownership
      end;

      FHttpResponseCode := Reader.HttpResponseCode;
      FHttpResponseHeaders := Reader.HttpResponseHeaders;
      Reader.HttpResponseHeaders := nil; // do not free HttpResponseHeaders in Reader destructor
      if FStatus = dsError then
        FErrorMessage := Reader.ErrorMessage;

      FreeAndNil(Reader);
      DoFinish;
      Exit; // DoFinish possibly freed us, so Exit and do not access any own fields
    end;

    // Reader continues to exist if and only if still dsDownloading
    Assert((Reader <> nil) = (FStatus = dsDownloading));
  end;
end;

procedure TUWPDownload.WaitForFinish;
begin
  while Status = dsDownloading do
  begin
    Update(nil);
    Sleep(10);
  end;
end;

{ TUrlAsynchronousReader }

procedure TUrlAsynchronousReader.Start;
begin
  Status := dsDownloading;
  TotalBytes := -1;
  ForceSynchronous := True;
end;

procedure TUrlAsynchronousReader.Update;
begin
  //
end;

{ TRegisteredProtocols }

procedure TRegisteredProtocols.Add(const Protocol: string;
  const ReadEvent: TUrlReadEvent; const WriteEvent: TUrlWriteEvent;
  const AsynchronousReader: TUrlAsynchronousReaderClass);
var
  P: TRegisteredProtocol;
begin
  if Find(Protocol) <> nil then
    raise Exception.Create('URL protocol "' + Protocol + '" is already registered');

  P := TRegisteredProtocol.Create;
  P.Protocol := Protocol;
  P.ReadEvent := ReadEvent;
  P.WriteEvent := WriteEvent;
  P.AsynchronousReader :=  AsynchronousReader;
  inherited Add(P);
end;

function TRegisteredProtocols.Find(const Protocol: string): TRegisteredProtocol;
begin
  for Result in Self do
    if Result.Protocol = Protocol then
      Exit;
  Result := nil;
end;

end.
