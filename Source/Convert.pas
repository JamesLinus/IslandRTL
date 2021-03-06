﻿namespace RemObjects.Elements.System;

type
  Convert = public static class
  private
    class const DecimalChar: Char = '.';
    method ParseString(s:String; out aSign: Boolean; out arr: array of Byte): Boolean;
    begin
      if String.IsNullOrEmpty(s) then exit False;
      var len:= s.Length;
      var start:=0;
      aSign := False;
      while s[start] = ' ' do begin
        inc(start);
        dec(len);
      end;
      while s[start+len-1] = ' ' do
        dec(len);


      if (s[start] = '-') or (s[start] = '+') then begin
        aSign := (s[start] = '-');
        dec(len);
        inc(start);
      end;
      arr := new array of Byte(len);
      for i: Integer := 0 to len-1 do begin
        var b:= Integer(s[i+start]);
        if (b>=48) and (b<=57) then arr[i] := b-48 else exit false;
      end;
      exit true;
    end;

    method ParseHex(s:String; out arr: array of Byte): Boolean;
    begin
      if String.IsNullOrEmpty(s) then exit False;
      var si := s.ToLower(True);
      var len:= si.Length;
      var start:=0;
      while si[start] = ' ' do begin
        inc(start);
        dec(len);
      end;

      while si[start+len-1] = ' ' do
        dec(len);

      arr := new array of Byte(len);
      for i: Integer := 0 to len-1 do begin
        var b:= Integer(si[i+start]);
        case b of
          48..57  {0..9}: arr[i] := b-48;
          97..102 {a..f}: arr[i] := b-87;
        else
          exit false;
        end;
      end;
      exit true;
    end;

  assembly
    method RaiseOverflowException;
    begin
      raise new OverflowException('overflow.');
    end;

    method RaiseFormatException;
    begin
      raise new FormatException('bad format.');
    end;

    method RaiseBadHexString;
    begin
      raise new FormatException('bad hex format.');
    end;

  public
    method TryParseInt64(s: String; out Value: Int64; aRaiseOverflowException: Boolean):Boolean;
    begin
      var lSign: Boolean;
      var arr: array of Byte;
      if not ParseString(s, out lSign, out arr) then exit false;
      var sValue:UInt64 := arr[0];
      var aMaxValue: UInt64 := iif(lSign, - Int64.MinValue, Int64.MaxValue);
      var aMaxValue1: UInt64 := (UInt64(iif(lSign, - Int64.MinValue, Int64.MaxValue)) / 10)+1;

      for i:Integer := 1 to arr.Length-1 do begin
        if (sValue> aMaxValue1) or (sValue*10 > (aMaxValue- arr[i])) then begin
          if aRaiseOverflowException then
            RaiseOverflowException
          else
            exit False;
        end;
        sValue := sValue*10+arr[i];
      end;
      Value := sValue;
      if lSign then Value := -Value;
      exit true;
    end;

    method TryParseUInt64(s: String; out Value: UInt64; aRaiseOverflowException: Boolean): Boolean;
    begin
      var lSign: Boolean;
      var arr: array of Byte;
      if not ParseString(s, out lSign, out arr) then exit false;
      if lSign then exit False;
      var sValue : UInt64 := arr[0];

      for i:Integer := 1 to arr.Length-1 do begin
        if (sValue > UInt64.MaxValue / 10) or (sValue*10 > UInt64.MaxValue - arr[i]) then begin
          if aRaiseOverflowException then
            RaiseOverflowException
          else
            exit False;
        end;
        sValue := sValue*10+arr[i];
      end;
      Value := sValue;
      exit true;
    end;

    method HexStringToUInt64(s: String): UInt64;
    begin
      var arr: array of Byte;
      if not ParseHex(s,out arr) then RaiseBadHexString;
      var sValue : UInt64 := arr[0];

      for i:Integer := 1 to arr.Length-1 do begin
        if (sValue > UInt64.MaxValue shr 4) or (sValue shl 4 > UInt64.MaxValue - arr[i]) then RaiseOverflowException;
        sValue := (sValue shl 4)+arr[i];
      end;
      exit sValue;
    end;

    method UInt64ToHexString(v: UInt64; aDigits: Integer): String;
    begin
      if aDigits < 1 then raise new Exception('aDigits must be great than 0');
      var arr:= new array of Char(aDigits);

      var a_pos := aDigits-1;
      var lv := v;
      while (lv > 0) and (aDigits >-1) do begin
        var lv1 := lv shr 4;
        var lv2 := lv - (lv1 shl 4);
        case lv2 of
          0..9 : arr[a_pos] := Char(lv2+48);
          10..15: arr[a_pos] := Char(lv2+87);
        else
          raise new Exception('this place should be never reached');
        end;
        lv := lv1;
        dec(a_pos);
      end;
      for i: Integer := 0 to a_pos do
        arr[i] := '0';
      exit String.FromPChar(@arr[0],aDigits);
    end;

    method TryParseDouble(s: String; out Value: Double; aRaiseOverflowException: Boolean):Boolean;
    begin
      //[ws][sign]integral-digits[.[fractional-digits]][e[sign]exponential-digits][ws] 

      if String.IsNullOrEmpty(s) then exit false; //empty string
      s := s.Trim;
      if String.IsNullOrEmpty(s) then exit false; //empty string

      var sdot := s.IndexOf(DecimalChar);
      var se := s.IndexOf('e');
      if se = -1 then se := s.IndexOf('E');
      if (se <> -1) and (sdot <> -1) and (sdot>se) then exit false;
      var lSign: Boolean;
      var arr: array of Byte;
      var s1 := '';
      if sdot <> -1 then begin
        s1 := s.Substring(0,sdot);
      end
      else if se <> -1 then begin
        s1 := s.Substring(0,se);
      end
      else begin
        s1 := s;
      end;
      if String.IsNullOrEmpty(s1) then exit false;
      if not ParseString(s1, out lSign, out arr) then exit false;
      var sValue:Double := arr[0];
      for i:Integer := 1 to arr.Length-1 do begin
        if (sValue> Double.MaxValue) or (sValue*10 > (Double.MaxValue- arr[i])) then begin
          if aRaiseOverflowException then
            RaiseOverflowException
          else
            exit False;
        end;
        sValue := sValue*10+arr[i];
      end;
      
      var arr1: array of Byte;
      if (sdot <> -1) then begin
        if (se <> -1) then begin                 
          s1 := s.Substring(sdot+1,(se-sdot)-1);
        end
        else begin
          s1 := s.Substring(sdot+1);        
        end;
        // xxx.xxx
        // xxx.
        if not String.IsNullOrEmpty(s1) then begin
          var lsign1: Boolean;
          if not ParseString(s1, out lsign1, out arr1) then exit false;        
          if lsign1 then exit false;
          var sfract: Double:=arr1[arr1.Length-1];
          for i:Integer := arr1.Length-2 downto 0 do begin
            sfract := sfract*0.1+arr1[i];
          end;
          sValue := sValue+sfract*0.1;
        end;
      end;
      if se <> -1 then begin
        s1 := s.Substring(se+1);
        var exp: Int64;
        if not TryParseInt64(s1,out exp,aRaiseOverflowException) then exit false;
        //xxxx.xxx
        var lexp := exp+arr.Count-1;
        // 0.xxxxx
        if (arr.Count = 1) and (arr[0] = 0) and (sdot<>-1) then begin
          for i:Integer:=0 to arr1.Count-1 do
            if arr1[i] = 0 then 
              dec(lexp)
            else 
              break;
        end;
        if (lexp > 308)or (lexp<-308) then 
          if aRaiseOverflowException then 
            RaiseOverflowException
          else 
            exit false;
        if lexp = 308 then begin
          sValue := sValue *  Math.Pow(10, exp-1);
          if sValue > Double.MaxValue /10 then begin
            if aRaiseOverflowException then 
              RaiseOverflowException
            else 
              exit false;
          end;
          sValue := sValue*10;
        end
        else if lexp = -308 then begin
          sValue := sValue *  Math.Pow(10, exp+1);
          if -sValue < Double.MinValue *10 then begin
            if aRaiseOverflowException then 
              RaiseOverflowException
            else 
              exit false;
          end;
          sValue := sValue*0.1;
        end
        else begin
          sValue := sValue *  Math.Pow(10, exp);
        end;
      end;
      if lSign then sValue := -sValue;  
      Value := sValue;
      exit True;
    end;

  end;

end.