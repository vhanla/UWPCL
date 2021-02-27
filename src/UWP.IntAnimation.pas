unit UWP.IntAnimation;

interface

uses
  Classes, Threading;

type
  TAniSyncProc = reference to procedure (V: Integer);
  TAniDoneProc = reference to procedure;
  TAniFunction = reference to function (P: Single): Single;

  TAniKind = (akIn, akOut, akInOut);

  TAniFunctionKind =
  (
    afkLinear, afkQuadratic, afkCubic, afkQuartic, afkQuintic,
    afkBack, afkBounce, afkExpo, afkSine, afkCircle
  );

  TIntAniSet = class(TPersistent)
  private
    FAniKind: TAniKind;
    FAniFunctionKind: TAniFunctionKind;
    FDelayStartTime: Cardinal;
    FDuration: Cardinal;
    FStep: Cardinal;
  public
    constructor Create;
    procedure Assign(ASource: TPersistent); override;
    procedure QuickAssign(AAniKind: TAniKind; AAniFunctionKind: TAniFunctionKind;
      ADelay, ADuration, AStep: Cardinal);
  published
    property AniKind: TAniKind read FAniKind write FAniKind;
    property AniFunctionKind: TAniFunctionKind read FAniFunctionKind write FAniFunctionKind;
    property DelayStartTime: Cardinal read FDelayStartTime write FDelayStartTime;
    property Duration: Cardinal read FDuration write FDuration;
    property Step: Cardinal read FStep write FStep;
  end;

  TIntAni = class(TThread)
  var CurrentValue: Integer;
  private
    var AniFunction: TAniFunction;

    FOnSync: TAniSyncProc;
    FOnDone: TAniDoneProc;
    FAniSet: TIntAniSet;
    FStartValue: Integer;
    FDeltaValue: Integer;

    function UpdateFunction: Boolean;
    procedure UpdateControl;
    procedure DoneControl;

  protected
    procedure Execute; override;

  public
    constructor Create(AStartValue, ADeltaValue: Integer;
      ASyncProc: TAniSyncProc; ADoneProc: TAniDoneProc);
    destructor Destroy; override;

    // Events
    property OnSync: TAniSyncProc read FOnSync write FOnSync;
    property OnDone: TAniDoneProc read FOnDone write FOnDone;

    // Properties
    property AniSet: TIntAniSet read FAniSet write FAniSet;
    property StartValue: Integer read FStartValue write FStartValue default 0;
    property DeltaValue: Integer read FDeltaValue write FDeltaValue default 0;
  end;

implementation

uses
  SysUtils, Math, UWP.IntAnimation.Collection;

{ TIntAni }

constructor TIntAni.Create(AStartValue, ADeltaValue: Integer;
  ASyncProc: TAniSyncProc; ADoneProc: TAniDoneProc);
begin
  inherited Create(True);
  FreeOnTerminate := True;

  // Internal
  CurrentValue := 0;
  AniFunction := nil;

  // AniSet
  FAniSet := TIntAniSet.Create;
  FAniSet.QuickAssign(akOut, afkLinear, 0, 200, 20);

  // Fields
  FStartValue := AStartValue;
  FDeltaValue := ADeltaValue;
  FOnSync := ASyncProc;
  FOnDone := ADoneProc;

  // Finish
  UpdateFunction;
end;

destructor TIntAni.Destroy;
begin
  FAniSet.Free;
  inherited;
end;

procedure TIntAni.DoneControl;
begin
  if Assigned(FOnDone) then
    FOnDone();
end;

procedure TIntAni.Execute;
var
  I: Cardinal;
  t, d, TimerPerStep: Cardinal;
  b, c: Integer;
begin
  if UpdateFunction = False then Exit;
  /// Update easing function 
  /// Depend on AniKind (In, Out, ...) and AniFunctionKind (Linear, ...)
  /// If Result = False (error found), then exit

  d := AniSet.Duration;
  b := StartValue;
  c := DeltaValue;

  // Delay Start
  Sleep(AniSet.DelayStartTime);

  // Calc step by FPS
  TimerPerStep := Round(d / AniSet.Step);

  // Run
  for I := 1 to AniSet.Step - 1 do
  begin
    t := I * TimerPerStep;
    CurrentValue := b + Round(c * AniFunction(t / d));
    Synchronize(UpdateControl);
    Sleep(TimerPerStep);
  end;

  // Last step
  t := d;
  CurrentValue := b + Round(c * AniFunction(t / d));
  Synchronize(UpdateControl);

  // Finish
  Synchronize(DoneControl);
  //inherited;
end;

procedure TIntAni.UpdateControl;
begin
  if Assigned(FOnSync) then
    FOnSync(CurrentValue);
end;

function TIntAni.UpdateFunction: Boolean;
begin
  Result := True;
  case AniSet.AniKind of
    akIn: 
      case AniSet.AniFunctionKind of
        afkLinear:
          AniFunction := TIntAniCollection.Linear;
        afkQuadratic:
          AniFunction := TIntAniCollection.Quadratic_In;
        afkCubic:
          AniFunction := TIntAniCollection.Cubic_In;
        afkQuartic:
          AniFunction := TIntAniCollection.Quartic_In;
        afkQuintic:
          AniFunction := TIntAniCollection.Quintic_In;
        afkBack:
          AniFunction := TIntAniCollection.Back_In;
        afkBounce:
          AniFunction := TIntAniCollection.Bounce_In;
        afkExpo:
          AniFunction := TIntAniCollection.Expo_In;
        afkSine:
          AniFunction := TIntAniCollection.Sine_In;
        afkCircle:
          AniFunction := TIntAniCollection.Circle_In;
        else
          Result := False;
      end;
    akOut:
      case AniSet.AniFunctionKind of
        afkLinear:
          AniFunction := TIntAniCollection.Linear;
        afkQuadratic:
          AniFunction := TIntAniCollection.Quadratic_Out;
        afkCubic:
          AniFunction := TIntAniCollection.Cubic_Out;
        afkQuartic:
          AniFunction := TIntAniCollection.Quartic_Out;
        afkQuintic:
          AniFunction := TIntAniCollection.Quintic_Out;
        afkBack:
          AniFunction := TIntAniCollection.Back_Out;
        afkBounce:
          AniFunction := TIntAniCollection.Bounce_Out;
        afkExpo:
          AniFunction := TIntAniCollection.Expo_Out;
        afkSine:
          AniFunction := TIntAniCollection.Sine_Out;
        afkCircle:
          AniFunction := TIntAniCollection.Circle_Out;
        else
          Result := False;
      end;
    akInOut:
      case AniSet.AniFunctionKind of
        afkLinear:
          AniFunction := TIntAniCollection.Linear;
        afkQuadratic:
          AniFunction := TIntAniCollection.Quadratic_InOut;
        afkCubic:
          AniFunction := TIntAniCollection.Cubic_InOut;
        afkQuartic:
          AniFunction := TIntAniCollection.Quartic_InOut;
        afkQuintic:
          AniFunction := TIntAniCollection.Quintic_InOut;
        afkBack:
          AniFunction := TIntAniCollection.Back_InOut;
        afkBounce:
          AniFunction := TIntAniCollection.Bounce_InOut;
        afkExpo:
          AniFunction := TIntAniCollection.Expo_InOut;
        afkSine:
          AniFunction := TIntAniCollection.Sine_InOut;
        afkCircle:
          AniFunction := TIntAniCollection.Circle_InOut;
        else
          Result := False;
      end;
    else
      Result := False;
  end;
end;

{ TIntAniSet }

procedure TIntAniSet.Assign(ASource: TPersistent);
begin
  if ASource is TIntAniSet then
  begin
    FAniKind := TIntAniSet(ASource).AniKind;
    FAniFunctionKind := TIntAniSet(ASource).AniFunctionKind;
    FDelayStartTime := TIntAniSet(ASource).DelayStartTime;
    FDuration := TIntAniSet(ASource).Duration;
    FStep := TIntAniSet(ASource).Step;
  end
  else
    inherited;
end;

constructor TIntAniSet.Create;
begin
  inherited Create;
  FAniKind := akOut;
  FAniFunctionKind := afkLinear;
  FDelayStartTime := 0;
  FDuration := 200;
  FStep := 20;
end;

procedure TIntAniSet.QuickAssign(AAniKind: TAniKind;
  AAniFunctionKind: TAniFunctionKind; ADelay, ADuration, AStep: Cardinal);
begin
  FAniKind := AAniKind;
  FAniFunctionKind := AAniFunctionKind;
  FDelayStartTime := ADelay;
  FDuration := ADuration;
  FStep := AStep;
end;

end.
