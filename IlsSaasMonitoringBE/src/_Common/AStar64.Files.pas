﻿unit AStar64.Files;
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
interface

uses
  SysUtils, Windows,
  AStar64.FileStructs,
  Geo.Pos,
  UStructArray;

const
  C5FileTypes = [ftEdgeF, ftEdgeB, ftListF, ftListB, ftWay];
  C6FileTypes = [ftEdgeF, ftEdgeB, ftListF, ftListB, ftWay, ftSpeed];
  C7FileTypes = [ftEdgeF, ftEdgeB, ftListF, ftListB, ftWay, ftZCF, ftZCB];
  C8FileTypes = [ftEdgeF, ftEdgeB, ftListF, ftListB, ftWay, ftZCF, ftZCB, ftSpeed];
  C9FileTypes = [ftEdgeF, ftEdgeB, ftListF, ftListB, ftWay, ftZCF, ftZCB, ftSCF, ftSCB];
//------------------------------------------------------------------------------
type

//------------------------------------------------------------------------------
//! именнованные классы-хэлперы массивов
//------------------------------------------------------------------------------
  TEdgeLoader = TStructArray<TEdge>;
  TListLoader = TStructArray<THashVector>;
  TWayLoader = TStructArray<TWayPoint>;
  TZCLoader = TStructArray<TZoneControl>;
  TSCLoader = TStructArray<TSignControl>;
  TSpeedLoader = TStructArray<TSpeedControl>;

//------------------------------------------------------------------------------
//! хранилище загруженных файлов
//------------------------------------------------------------------------------
  THoldRec = record
    EdgeForward, EdgeBackward: TEdgeArray;
    ListForward, ListBackward: THashVectorArray;
    ZCForward, ZCBackward: TZoneControlArray;
    SCForward, SCBackward: TSignControlArray;
    Ways: TGeoPosArray;
    Speeds: TSpeedControlArray;
    procedure Clear;
  end;

  THoldRecArray = TArray<THoldRec>;

//------------------------------------------------------------------------------
//!
//------------------------------------------------------------------------------
  ENoGraphFile = class(Exception);

//------------------------------------------------------------------------------
//!
//------------------------------------------------------------------------------
  TGFAdapter = class
  private
    class procedure MakeBak(
      const AFileName: string
    );
    class procedure DelBak(
      const AFileName: string
    );
  public
    class procedure Load(
      const ARootPath: string;
      const AAccounts: array of Integer;
      const AHash: string;
      var RHolder: THoldRec
    );
    class procedure LoadFileType(
      const ARootPath: string;
      const AAccounts: array of Integer;
      const AHash: string;
      var RHolder: THoldRec;
      const AFiles: TFileTypeSet
    );
    class procedure Save(
      const ARootPath: string;
      const AAccount: Integer;
      const AHash: string;
      const AHolder: THoldRec;
      const AFiles: TFileTypeSet
    );
    class function Copy5Files(
      const ARootPath: string;
      const AAccounts: array of Integer;
      const AHash: string) : boolean;
    class function Copy6Files(
      const ARootPath: string;
      const AAccounts: array of Integer;
      const AHash: string) : boolean;
  end;

var
  //TODO: необходимо выкинуть эти переменные после профилировки или обложить условным компилированием
  gt: TDateTime;
  gc: Integer;
  //TODO:^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//------------------------------------------------------------------------------
implementation

//------------------------------------------------------------------------------
const

//------------------------------------------------------------------------------
//!
//------------------------------------------------------------------------------
  CBakExt = '.bak';
  CNotEqual = 'количество элементов файла "%s" не соответствует количеству элементов файла "%s"';

//------------------------------------------------------------------------------
// TGFAdapter
//------------------------------------------------------------------------------

class procedure TGFAdapter.Load(
  const ARootPath: string;
  const AAccounts: array of Integer;
  const AHash: string;
  var RHolder: THoldRec
);
var
  Iter: TFileType;
  AccIter: Integer;
  RootPath: string;
  AllPath: array[Low(TFileType)..High(TFileType)] of string;
//------------------------------------------------------------------------------

function InternalLoad(): Boolean;
  var
    st, et: TDateTime;
begin
  Result := FileExists(AllPath[ftEdgeF])
    and FileExists(AllPath[ftEdgeB])
    and FileExists(AllPath[ftListF])
    and FileExists(AllPath[ftListB])
    and FileExists(AllPath[ftWay]);
  if not Result then
    Exit;
  st := Now;
  //
  TEdgeLoader.LoadFromFile(AllPath[ftEdgeF], RHolder.EdgeForward);
  TEdgeLoader.LoadFromFile(AllPath[ftEdgeB], RHolder.EdgeBackward);
  TListLoader.LoadFromFile(AllPath[ftListF], RHolder.ListForward);
  TListLoader.LoadFromFile(AllPath[ftListB], RHolder.ListBackward);
  TWayLoader.LoadFromFile(AllPath[ftWay], RHolder.Ways);
  TZCLoader.LoadFromFile(AllPath[ftZCF], RHolder.ZCForward);
  TZCLoader.LoadFromFile(AllPath[ftZCB], RHolder.ZCBackward);
  TSCLoader.LoadFromFile(AllPath[ftSCF], RHolder.SCForward);
  TSCLoader.LoadFromFile(AllPath[ftSCB], RHolder.SCBackward);
  TSpeedLoader.LoadFromFile(AllPath[ftSpeed], RHolder.Speeds);
  //
  if (Length(RHolder.ZCForward) = 0) then
    SetLength(RHolder.ZCForward, Length(RHolder.EdgeForward))
  else
    if (Length(RHolder.ZCForward) <> Length(RHolder.EdgeForward)) then
      raise Exception.CreateFmt(CNotEqual, [AllPath[ftZCF], AllPath[ftEdgeF]]);
  if (Length(RHolder.ZCBackward) = 0) then
    SetLength(RHolder.ZCBackward, Length(RHolder.EdgeBackward))
  else
    if (Length(RHolder.ZCBackward) <> Length(RHolder.EdgeBackward)) then
      raise Exception.CreateFmt(CNotEqual, [AllPath[ftZCB], AllPath[ftEdgeB]]);
  //
  if (Length(RHolder.SCForward) = 0) then
    SetLength(RHolder.SCForward, Length(RHolder.EdgeForward))
  else
    if (Length(RHolder.SCForward) <> Length(RHolder.EdgeForward)) then
      raise Exception.CreateFmt(CNotEqual, [AllPath[ftSCF], AllPath[ftEdgeF]]);
  if (Length(RHolder.SCBackward) = 0) then
    SetLength(RHolder.SCBackward, Length(RHolder.EdgeBackward))
  else
    if (Length(RHolder.SCBackward) <> Length(RHolder.EdgeBackward)) then
      raise Exception.CreateFmt(CNotEqual, [AllPath[ftSCB], AllPath[ftEdgeB]]);
  //
  if (Length(RHolder.Speeds) = 0) then
    SetLength(RHolder.Speeds, Length(RHolder.EdgeForward))
  else
    if (Length(RHolder.Speeds) <> Length(RHolder.EdgeForward)) then
      raise Exception.CreateFmt(CNotEqual, [AllPath[ftSpeed], AllPath[ftEdgeF]]);
  et := Now - st;
  gt := gt + et;
  Inc(gc);
end;

begin
  SetLength(RHolder.EdgeForward, 0);
  SetLength(RHolder.EdgeBackward, 0);
  SetLength(RHolder.ListForward, 0);
  SetLength(RHolder.ListBackward, 0);
  SetLength(RHolder.ZCForward, 0);
  SetLength(RHolder.ZCBackward, 0);
  SetLength(RHolder.SCForward, 0);
  SetLength(RHolder.SCBackward, 0);
  SetLength(RHolder.Ways, 0);
  SetLength(RHolder.Speeds, 0);
  // по аккаунтам
  for AccIter in AAccounts do
  begin
    RootPath := ARootPath{D:\IGF\}
      + IntToStr(AccIter) + PathDelim{\}
      + Copy(AHash, 1, 1){u} + PathDelim{\}
      + Copy(AHash, 1, 2){uc} + PathDelim{\}
      + Copy(AHash, 1, 3){ucf} + PathDelim{\}
      + Copy(AHash, 1, 4){ucft} + PathDelim{\};
    for Iter := Low(TFileType) to High(TFileType) do
    begin
      AllPath[Iter] := RootPath + AHash + CFileType[Iter];
    end;
    if InternalLoad() then
      Exit;
  end;
  // не нашли нужных файлов :(
//  raise ENoGraphFile.CreateFmt('в заданном пути "%s" не найдено обязательных файлов', [RootPath + AHash]);
end;

class procedure TGFAdapter.LoadFileType(
      const ARootPath: string;
      const AAccounts: array of Integer;
      const AHash: string;
      var RHolder: THoldRec;
      const AFiles: TFileTypeSet
);
var
  Iter: TFileType;
  AccIter: Integer;
  RootPath: string;
  AllPath: array[Low(TFileType)..High(TFileType)] of string;
//------------------------------------------------------------------------------

function InternalLoad(): Boolean;
var
//  Iter: TFileType;
  i: Integer;
begin
//  Result := True;
(*    for Iter := Low(TFileType) to High(TFileType) do
      if Iter in AFiles then
        Result := Result and FileExists(AllPath[Iter]);

{  Result := FileExists(AllPath[ftEdgeF])
    and FileExists(AllPath[ftEdgeB])
    and FileExists(AllPath[ftListF])
    and FileExists(AllPath[ftListB])
    and FileExists(AllPath[ftWay]);}
  if not Result then
    Exit;                               }*)
  //
  Result := FileExists(AllPath[ftEdgeF])
    and FileExists(AllPath[ftEdgeB])
    and FileExists(AllPath[ftWay]);

  if (ftEdgeF in AFiles) then
    TEdgeLoader.LoadFromFile(AllPath[ftEdgeF], RHolder.EdgeForward);
  if (ftEdgeB in AFiles) then
    TEdgeLoader.LoadFromFile(AllPath[ftEdgeB], RHolder.EdgeBackward);
  if (ftListF in AFiles) then
    TListLoader.LoadFromFile(AllPath[ftListF], RHolder.ListForward);
  if (ftListB in AFiles) then
    TListLoader.LoadFromFile(AllPath[ftListB], RHolder.ListBackward);
  if (ftWay in AFiles) then
    TWayLoader.LoadFromFile(AllPath[ftWay], RHolder.Ways);
  if (ftZCF in AFiles) then
    TZCLoader.LoadFromFile(AllPath[ftZCF], RHolder.ZCForward);
  if (ftZCB in AFiles) then
    TZCLoader.LoadFromFile(AllPath[ftZCB], RHolder.ZCBackward);
  if (ftSCF in AFiles) then
    TSCLoader.LoadFromFile(AllPath[ftSCF], RHolder.SCForward);
  if (ftSCB in AFiles) then
    TSCLoader.LoadFromFile(AllPath[ftSCB], RHolder.SCBackward);
  if (ftSpeed in AFiles) then
    if FileExists(AllPath[ftSpeed]) then
      TSpeedLoader.LoadFromFile(AllPath[ftSpeed], RHolder.Speeds)
    else
    begin
      SetLength(RHolder.Speeds, Length(RHolder.EdgeForward));
      //проставляем скорости из дорог
      for I := Low(RHolder.EdgeForward) to High(RHolder.EdgeForward) do
        FillChar(RHolder.Speeds[i], SizeOf(TSpeedControl), RHolder.EdgeForward[i].MaxSpeed);
    end;
  //
  if (ftZCF in AFiles) then
    if (Length(RHolder.ZCForward) = 0) then
      SetLength(RHolder.ZCForward, Length(RHolder.EdgeForward))
    else
      if (Length(RHolder.ZCForward) <> Length(RHolder.EdgeForward)) then
        raise Exception.CreateFmt(CNotEqual, [AllPath[ftZCF], AllPath[ftEdgeF]]);
  if (ftZCB in AFiles) then
    if (Length(RHolder.ZCBackward) = 0) then
      SetLength(RHolder.ZCBackward, Length(RHolder.EdgeBackward))
    else
      if (Length(RHolder.ZCBackward) <> Length(RHolder.EdgeBackward)) then
        raise Exception.CreateFmt(CNotEqual, [AllPath[ftZCB], AllPath[ftEdgeB]]);
  //
  if (ftSCF in AFiles) then
    if (Length(RHolder.SCForward) = 0) then
      SetLength(RHolder.SCForward, Length(RHolder.EdgeForward))
    else
      if (Length(RHolder.SCForward) <> Length(RHolder.EdgeForward)) then
        raise Exception.CreateFmt(CNotEqual, [AllPath[ftSCF], AllPath[ftEdgeF]]);
  if (ftSCB in AFiles) then
    if (Length(RHolder.SCBackward) = 0) then
      SetLength(RHolder.SCBackward, Length(RHolder.EdgeBackward))
    else
      if (Length(RHolder.SCBackward) <> Length(RHolder.EdgeBackward)) then
        raise Exception.CreateFmt(CNotEqual, [AllPath[ftSCB], AllPath[ftEdgeB]]);
  //
  if (ftSpeed in AFiles) then
    if (Length(RHolder.Speeds) = 0) then
      SetLength(RHolder.Speeds, Length(RHolder.EdgeForward))
    else
      if (Length(RHolder.Speeds) <> Length(RHolder.EdgeForward)) then
        raise Exception.CreateFmt(CNotEqual, [AllPath[ftSpeed], AllPath[ftEdgeF]]);
end;

begin
  SetLength(RHolder.EdgeForward, 0);
  SetLength(RHolder.EdgeBackward, 0);
  SetLength(RHolder.ListForward, 0);
  SetLength(RHolder.ListBackward, 0);
  SetLength(RHolder.ZCForward, 0);
  SetLength(RHolder.ZCBackward, 0);
  SetLength(RHolder.SCForward, 0);
  SetLength(RHolder.SCBackward, 0);
  SetLength(RHolder.Ways, 0);
  SetLength(RHolder.Speeds, 0);
  // по аккаунтам
  for AccIter in AAccounts do
  begin
    RootPath := ARootPath{D:\IGF\}
      + IntToStr(AccIter) + PathDelim{\}
      + Copy(AHash, 1, 1){u} + PathDelim{\}
      + Copy(AHash, 1, 2){uc} + PathDelim{\}
      + Copy(AHash, 1, 3){ucf} + PathDelim{\}
      + Copy(AHash, 1, 4){ucft} + PathDelim{\};
    for Iter := Low(TFileType) to High(TFileType) do
//    for Iter := Low(AFiles) to High(AFiles) do
    begin
      if Iter in AFiles then
        AllPath[Iter] := RootPath + AHash + CFileType[Iter];
    end;
    if InternalLoad() then
      Exit;
  end;
  // не нашли нужных файлов :(
//  raise ENoGraphFile.CreateFmt('в заданном пути "%s" не найдено обязательных файлов', [RootPath + AHash]);
end;

class procedure TGFAdapter.Save(
  const ARootPath: string;
  const AAccount: Integer;
  const AHash: string;
  const AHolder: THoldRec;
  const AFiles: TFileTypeSet
);
var
  Iter: TFileType;
  RootPath: string;
  AllPath: array[Low(TFileType)..High(TFileType)] of string;
//------------------------------------------------------------------------------
begin
  // path
  RootPath := ARootPath{D:\IGF\}
    + IntToStr(AAccount) + PathDelim{\}
    + Copy(AHash, 1, 1){u} + PathDelim{\}
    + Copy(AHash, 1, 2){uc} + PathDelim{\}
    + Copy(AHash, 1, 3){ucf} + PathDelim{\}
    + Copy(AHash, 1, 4){ucft} + PathDelim{\};
  // каталог
  ForceDirectories(RootPath);
  // backup
  for Iter in AFiles do
  begin
    AllPath[Iter] := RootPath + AHash + CFileType[Iter];
    MakeBak(AllPath[Iter]);
  end;
  // work
  if (ftEdgeF in AFiles) then
    TEdgeLoader.SaveToFile(AHolder.EdgeForward, AllPath[ftEdgeF]);
  if (ftEdgeB in AFiles) then
    TEdgeLoader.SaveToFile(AHolder.EdgeBackward, AllPath[ftEdgeB]);
  if (ftListF in AFiles) then
    TListLoader.SaveToFile(AHolder.ListForward, AllPath[ftListF]);
  if (ftListB in AFiles) then
    TListLoader.SaveToFile(AHolder.ListBackward, AllPath[ftListB]);
  if (ftWay in AFiles) then
    TWayLoader.SaveToFile(AHolder.Ways, AllPath[ftWay]);
  if (ftZCF in AFiles) then
    TZCLoader.SaveToFile(AHolder.ZCForward, AllPath[ftZCF]);
  if (ftZCB in AFiles) then
    TZCLoader.SaveToFile(AHolder.ZCBackward, AllPath[ftZCB]);
  if (ftSCF in AFiles) then
    TSCLoader.SaveToFile(AHolder.SCForward, AllPath[ftSCF]);
  if (ftSCB in AFiles) then
    TSCLoader.SaveToFile(AHolder.SCBackward, AllPath[ftSCB]);
  if (ftSpeed in AFiles) then
    TSpeedLoader.SaveToFile(AHolder.Speeds, AllPath[ftSpeed]);
  //delbak ??? !!! ***
  for Iter in AFiles do
  begin
    DelBak(AllPath[Iter]);
  end;
end;

class procedure TGFAdapter.MakeBak(
  const AFileName: string
);
var
  BakFileName: string;
//------------------------------------------------------------------------------
begin
  BakFileName := AFilename + CBakExt;

  if not FileExists(AFileName) then Exit;

  DelBak(BakFileName);

  if not CopyFile(PChar(AFileName), PChar(BakFileName), False) then
    RaiseLastOSError();
end;

class function TGFAdapter.Copy5Files(const ARootPath: string;
  const AAccounts: array of Integer; const AHash: string): boolean;
var
  RHolder: THoldRec;
begin
  Load(ARootPath, AAccounts, AHash, RHolder);
  Save(ARootPath, AAccounts[0], AHash, RHolder, [ftEdgeF, ftEdgeB, ftListF, ftListB, ftWay]);
  Result := True;
end;

class function TGFAdapter.Copy6Files(const ARootPath: string;
  const AAccounts: array of Integer; const AHash: string): boolean;
var
  RHolder: THoldRec;
begin
  Load(ARootPath, AAccounts, AHash, RHolder);
  Save(ARootPath, AAccounts[0], AHash, RHolder, [ftEdgeF, ftEdgeB, ftListF, ftListB, ftWay, ftSpeed]);
  Result := True;
end;

class procedure TGFAdapter.DelBak(
  const AFileName: string
);
var
  BakFileName: string;
//------------------------------------------------------------------------------
begin
  BakFileName := AFilename + CBakExt;
  if not FileExists(BakFileName) then Exit;
  DeleteFile(PChar(BakFileName));
end;

{ THoldRec }

procedure THoldRec.Clear;
begin
  SetLength(EdgeForward, 0);
  SetLength(EdgeBackward, 0);
  SetLength(ListForward, 0);
  SetLength(ListBackward, 0);
  SetLength(ZCForward, 0);
  SetLength(ZCBackward, 0);
  SetLength(SCForward, 0);
  SetLength(SCBackward, 0);
  SetLength(Ways, 0);
  SetLength(Speeds, 0);
end;

end.
