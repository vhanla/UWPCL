{
  Canvas using Direct2D for faster alpha channel drawing.
}
unit UWP.D2D1Canvas;

interface

uses
  Classes, Windows, SysUtils,
  Winapi.D2D1,
  Winapi.DXTypes,
  Winapi.DxGiFormat,
  Winapi.DxgiType,
  Winapi.DXGI;

type

  ICanvas = interface
    function GetWidth: Single;
    function GetHeight: Single;
  end;

  TD2DCanvas = class(TInterfacedObject, ICanvas)
  private
    FWidth: Single;
    FHeight: Single;
    // property access methods
    function GetWidth: Single;
    function GetHeight: Single;

  public
    constructor Create;
  end;

  ICanvasHandler = interface
    ['{0F3EC368-6BAB-48B3-AD9B-2F6140A66207}']
    // factory methods
    function NewCanvas: ICanvas;
  end;

  TD2D1CanvasHandler = class(TInterfacedObject, ICanvasHandler)
    function NewCanvas: ICanvas;
    // classes
    class var SingletonD2DFactory: ID2D1Factory;
    class var SingletonRenderTarget: ID2D1DCRenderTarget;
    class function D2DFactory(factoryType: TD2D1FactoryType = D2D1_FACTORY_TYPE_SINGLE_THREADED;
      factoryOptions: PD2D1FactoryOptions = nil): ID2D1Factory; static;
    class function RT: ID2D1DCRenderTarget; static;
  end;

implementation


{ TD2D1CanvasHandler }

class function TD2D1CanvasHandler.D2DFactory(factoryType: TD2D1FactoryType;
  factoryOptions: PD2D1FactoryOptions): ID2D1Factory;
var
  LD2D1Factory: ID2D1Factory;
begin
  if SingletonD2DFactory = nil then
  begin
    if not Succeeded(D2D1CreateFactory(factoryType, IID_ID2D1Factory,
      factoryOptions, LD2D1Factory))
    then
      RaiseLastOSError;

    if InterlockedCompareExchangePointer(Pointer(SingletonD2DFactory), Pointer(LD2D1Factory), nil) = nil then
      LD2D1Factory._AddRef;
  end;
  Result := SingletonD2DFactory;
end;

function TD2D1CanvasHandler.NewCanvas: ICanvas;
begin
  Result := TD2DCanvas.Create;
end;

class function TD2D1CanvasHandler.RT: ID2D1DCRenderTarget;
var
  RenderTarget: ID2D1DCRenderTarget;
begin
  if SingletonRenderTarget = nil then
  begin
    if not Succeeded(D2DFactory.CreateDCRenderTarget(
      D2D1RenderTargetProperties(
        {$IFDEF GPUSupport}
          D2D1_RENDER_TARGET_TYPE_DEFAULT,
        {$ELSE}
          D2D1_RENDER_TARGET_TYPE_SOFTWARE, // much faster in low end gpus
        {$ENDIF}
        D2D1PixelFormat(DXGI_FORMAT_B8G8R8A8_UNORM, D2D1_ALPHA_MODE_PREMULTIPLIED),
        0, 0, D2D1_RENDER_TARGET_USAGE_GDI_COMPATIBLE),
        RenderTarget))
    then
      RaiseLastOSError;

    if InterlockedCompareExchangePointer(Pointer(SingletonRenderTarget),
      Pointer(RenderTarget), nil) = nil
    then
      SingletonRenderTarget._AddRef;
  end;
  Result := SingletonRenderTarget;
end;

{ TD2DCanvas }

constructor TD2DCanvas.Create;
begin
  //
end;

function TD2DCanvas.GetHeight: Single;
begin
  Result := FHeight;
end;

function TD2DCanvas.GetWidth: Single;
begin
  Result := FWidth;
end;

end.
