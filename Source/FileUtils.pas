﻿namespace RemObjects.Elements.System;

type
  TimeModifier = (Created, Updated, Accessed);


  FileUtils = assembly static class
  private
  protected
  public
  {$IFDEF WINDOWS}
    class method IsFolder(Attr: rtl.DWORD): Boolean; inline;
    begin
      if Attr = rtl.INVALID_FILE_ATTRIBUTES then exit false;
      exit (Attr and rtl.FILE_ATTRIBUTE_DIRECTORY) = rtl.FILE_ATTRIBUTE_DIRECTORY;
    end;
    class method IsFile(Attr: rtl.DWORD): Boolean; inline;
    begin
      if Attr = rtl.INVALID_FILE_ATTRIBUTES then exit false;
      exit (Attr and rtl.FILE_ATTRIBUTE_DIRECTORY) <> rtl.FILE_ATTRIBUTE_DIRECTORY;
    end;  
  {$ELSEIF POSIX}
    class method IsFolder(Attr: rtl.__mode_t): Boolean; inline;
    begin
      exit (Attr and rtl.S_IFMT) = rtl.S_IFDIR;
    end;
    class method IsFile(Attr: rtl.__mode_t): Boolean; inline;
    begin
      exit (Attr and rtl.S_IFMT) = rtl.S_IFREG;
    end;  
  {$ELSE}
  {$ERROR Unsupported platform}
  {$ENDIF}
    

    class method FolderExists(aFullName: not nullable String): Boolean;
    begin
      {$IFDEF WINDOWS}
      exit IsFolder(rtl.GetFileAttributesW(aFullName.ToFileName()));
      {$ELSEIF POSIX}
      exit IsFolder(Get__struct_stat(aFullName)^.st_mode);
      {$ELSE}{$ERROR}{$ENDIF}
    end;

    class method FileExists(aFullName: not nullable String): Boolean;
    begin
      {$IFDEF WINDOWS}
      exit IsFile(rtl.GetFileAttributesW(aFullName.ToFileName()));
      {$ELSEIF POSIX}
      exit IsFile(FileUtils.Get__struct_stat(aFullName)^.st_mode);
      {$ELSE}{$ERROR}
      {$ENDIF}
    end;

    {$IFDEF POSIX}
    class method Get__struct_stat(aFullName: String): ^rtl.__struct_stat;inline;
    begin
      var sb: rtl.__struct_stat;
      CheckForIOError(rtl.stat(aFullName.ToFileName(),@sb));
      exit @sb;
    end;
    {$ENDIF}

    {$IFDEF POSIX AND NOT ANDROID}
    [SymbolName('stat')]
    method stat(file: ^AnsiChar; buf: ^rtl.__struct_stat): Int32;
    begin
      exit rtl.__xstat(rtl._STAT_VER, file, buf);
    end;

    [SymbolName('fstat')]
    method fstat(fd: Int32; buf: ^rtl.__struct_stat): Int32;
    begin
      exit rtl.__fxstat(rtl._STAT_VER, fd, buf);
    end;

    {$ENDIF}

  end;

{$IFDEF WINDOWS}
extension method String.ToLPCWSTR: rtl.LPCWSTR; assembly;
begin
  if String.IsNullOrEmpty(self) then exit nil;
  var arr := ToCharArray(true);
  exit rtl.LPCWSTR(@arr[0]);
end;

extension method String.ToFileName: rtl.LPCWSTR; assembly;
begin
  if String.IsNullOrEmpty(self) then exit nil;
  exit ((if not self.StartsWith('\\?\') then '\\?\' else '')+self).ToLPCWSTR();
end;
{$ENDIF}

{$IFDEF POSIX}
extension method String.ToFileName: ^AnsiChar;assembly;
begin
  exit @self.ToAnsiChars(True)[0];
end;
{$ENDIF}

end.