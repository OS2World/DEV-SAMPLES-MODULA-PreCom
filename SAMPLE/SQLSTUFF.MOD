IMPLEMENTATION MODULE SQLStuff;
FROM SQLDA IMPORT sqlda,SQLVar,sqldaPtr,SQLHeader;
FROM SQLCA IMPORT sqlca;
FROM Storage IMPORT ALLOCATE,DEALLOCATE;
FROM SQL IMPORT SQLGINTP;
FROM Lib IMPORT Fill;
IMPORT SQL;
FROM FIO IMPORT File, StandardOutput,WrLn,WrStr,WrLngInt;
CONST
  DAVarSize  = SIZE(SQLVar);
  DAHeaderSize = SIZE(SQLHeader);

PROCEDURE AllocSQLDA( VAR TheDA : sqldaPtr; NbrVars : CARDINAL);
VAR
 S : CARDINAL;

BEGIN
  S := DAHeaderSize + (NbrVars * DAVarSize);
  ALLOCATE(TheDA,S);
  Fill(TheDA,S,0);
  TheDA^.header.sqlaid := 'SQLDA  ';
  TheDA^.header.sqln := NbrVars;
  TheDA^.header.sqldabc := LONGINT(S);

END AllocSQLDA;



PROCEDURE WhatSize(Var : SQLVar) : CARDINAL;
BEGIN
  CASE Var.type OF
    SQL.SQL_TYP_VARCHAR,
    SQL.SQL_TYP_NVARCHAR,
    SQL.SQL_TYP_LONG,
    SQL.SQL_TYP_NLONG    : RETURN Var.len + SIZE(CARDINAL);
  ELSE RETURN Var.len;
  END; (* end of case *)

END WhatSize;


PROCEDURE DeallocSQLDA(VAR TheDA : sqldaPtr);
VAR
 N : CARDINAL;
 J : CARDINAL;
 S : CARDINAL;
BEGIN
  N := CARDINAL(TheDA^.header.sqldabc);
  Fill(TheDA,N,0);
  DEALLOCATE(TheDA,N);
  TheDA := NIL;
END DeallocSQLDA;


PROCEDURE DefaultErrorRoutine( Handle : CARDINAL; Msg : ARRAY OF CHAR;
                               CA : sqlca);

  (* if the handle = 0 assume the standard output device *)

VAR
  H : File;
  L : CARDINAL;
  ErrMsg : ARRAY[0..800] OF CHAR;
BEGIN
 IF Handle = 0
   THEN H := StandardOutput;
   ELSE H := Handle;
 END;

 WrLn(H);
 WrStr(H,' SQL ERROR - ');
 WrLngInt(H,CA.sqlcode,3);
 WrLn(H);
 WrStr(H,Msg);
 WrLn(H);
 L := SIZE(ErrMsg);
 SQLGINTP(L,60,CA,ErrMsg);
 WrStr(H,ErrMsg);
 WrLn(H);
 WrStr(H,'   * * * * *');
 WrLn(H);


END DefaultErrorRoutine;


BEGIN
  SQLErrorHandler := DefaultErrorRoutine;
END SQLStuff.