IMPLEMENTATION MODULE ParseVar;
FROM Str IMPORT Copy,Pos,Slice,Length,StrToCard,Compare,Subst,
     Append,NextPos,Length;
FROM Lists IMPORT GenList,StrElmt;
FROM Lib IMPORT Fill;
FROM SQLCA IMPORT sqlca;
FROM SQLTypes IMPORT LongVChar;
IMPORT SQLPREP;

(* Manages the host variables
    Builds list of host variables
    registers the host variables as found
    returns ID of host variables

*)


TYPE
  M2Sql = RECORD
    M2Type : ARRAY[0..30] OF CHAR;
    SqlNbr : CARDINAL;
    M2Len  : CARDINAL;
    ObjectSuffix : ARRAY[0..10] OF CHAR;
  END;
  CharSet = SET OF CHAR;


CONST
  MaxM2Types = 30;
  ValidChar = CharSet{'0'..'9','A'..'Z','a'..'z','_', '[',']','.'};
  SQLChars  = CharSet{'0'..'9','A'..'Z','a'..'z',':',',','.','_','*',
                      '^','=','>','<','(',')','"',"'",'/','+','-'};
  TermSet   = CharSet{' ',',',':',')','('};

VAR
  M2Types : ARRAY[0..MaxM2Types] OF M2Sql;


PROCEDURE Pack(VAR Str : ARRAY OF CHAR);
(* remove blanks and other non-character stuff *)
VAR
  S : ARRAY[0..80] OF CHAR;
  J,K : CARDINAL;

BEGIN
  Copy(S,Str);
  Fill(ADR(Str),HIGH(Str),0);
  J := 0;
  K := 0;
  WHILE J <= Length(S) DO
    IF S[J] IN ValidChar
      THEN
        Str[K] := S[J];
        INC(K);
      END;
      INC(J);
  END;

END Pack;


PROCEDURE RemoveComment(VAR Line : ARRAY OF CHAR; VAR InComment: CARDINAL);
VAR Str : ARRAY[0..300] OF CHAR;
    J,K : CARDINAL;
   (* remove comments from the input line *)
   (* if will handle the case of nested comments and comments that span*)
   (* multiple lines *)
   (* will not handle the case of comment immediatly followed by comment*)
   (* with no space between (i.e.  *)

BEGIN
  Copy(Str,Line);
  Fill(ADR(Line),SIZE(Line),0);
  J := 0;
  K := 0;
  WHILE J < Length(Str) DO
    IF (Str[J] = '(') AND (Str[J+1] = '*' )
      THEN INC(InComment);
      END;
    IF (Str[J] = '*') AND (Str[J+1] = ')')
      THEN
        DEC(InComment);
        INC(J,2);
      END;
    IF InComment = 0
      THEN
        Line[K] := Str[J];
        INC(K);
      END;
    INC(J);
   END;   (* end of while *)
END RemoveComment;


VAR
  Location : CARDINAL;
PROCEDURE AddHostVar(Name : ARRAY OF CHAR;type,Len : CARDINAL; InSection : BOOLEAN);
VAR J : CARDINAL;
    LJ : LONGCARD;
    RC : CARDINAL;
    L : CARDINAL;
    CA : sqlca;
BEGIN
 INC(ProgVars.used);
 J := ProgVars.used;
 IF InSection
   THEN Location := SQLPREP.SQLA_DECLARE_SECT
   ELSE Location := SQLPREP.SQLA_SQL_STMT;
        type := 0;
        Len  := 0;
   END;
 Copy(ProgVars.Vars[J].Name,Name);
 ProgVars.Vars[J].Type := type;
 ProgVars.Vars[J].Len  := Len;
 ProgVars.Vars[J].ID   := J;
 L :=  Length(Name);
 LJ := LONGCARD(J);
 RC := SQLPREP.SQLGAHVR(L,Name,type,Len,LJ,Location,NIL,CA);
END AddHostVar;





PROCEDURE GetVarType(VarType : ARRAY OF CHAR; VAR SqlType, Len : CARDINAL): BOOLEAN;
 VAR
   ArrayBeginVal, ArrayEndVal : CARDINAL;
   J : CARDINAL;
   B,E : CARDINAL;
   S : ARRAY[0..5] OF CHAR;
   Ok : BOOLEAN;
   ArraySize : CARDINAL;

BEGIN
     (* if an array was specified - get size of array *)

  ArraySize := 1;     (* assume no array *)
  IF Pos(VarType,'[') < MAX(CARDINAL)  (* calc the size of array*)
   THEN
     B := Pos(VarType,'[');
     E := Pos(VarType,'..');
     Slice(S,VarType,B+1,(E-B-1));   (* isolate the variable type *)
     ArrayBeginVal := CARDINAL(StrToCard(S,10,Ok));
     B := Pos(VarType,'..');
     E := Pos(VarType,']');
     Slice(S,VarType,B+2,(E-B-2));
     ArrayEndVal := CARDINAL(StrToCard(S,10,Ok));
     ArraySize := (ArrayEndVal - ArrayBeginVal + 1);
   END;

  J := 0;   (* now look up the var type in the type table *)
  LOOP
    IF J > MaxM2Types
      THEN
        SqlType := 0;
        Len     := 0;
        RETURN FALSE;  (* var type not found - dont add*)
      END;
      IF Pos(VarType,M2Types[J].M2Type) < MAX(CARDINAL)
        THEN EXIT;
        ELSE INC(J);
      END;
  END; (* end of loop *)
    (* J now points to the type of m2 variable *)

  SqlType := M2Types[J].SqlNbr;
  Len := M2Types[J].M2Len * ArraySize;
  RETURN TRUE;

END GetVarType;

PROCEDURE GetVars(Line : ARRAY OF CHAR;VAR InComment: CARDINAL);
(* all variables must be typed on the same line *)
VAR
  P : CARDINAL;
  VarName : ARRAY[0..30] OF CHAR;
  M2Type  : ARRAY[0..40] OF CHAR;
  SqlType : CARDINAL;
  VarLen  : CARDINAL;
BEGIN
 RemoveComment(Line,InComment);
 P := Pos(Line,':');    (* if a variable in this line *)
 IF P = MAX(CARDINAL)   (* no variable on this line *)
   THEN RETURN;
   END;
 Slice(VarName,Line,0,P); (* get the left side of var type*)
 Slice(M2Type,Line,P+1,Length(Line)); (* get the type *)
 Subst(M2Type,'OF','  ');
 Pack(M2Type);
 Pack(VarName);
 IF GetVarType(M2Type,SqlType,VarLen)
   THEN AddHostVar(VarName,SqlType,VarLen,TRUE);
   END;

(* based on the M2 type - assign an SQL type *)


END GetVars;

  (* given a host variable, return the variable ID*)




PROCEDURE GetID(VarName : ARRAY OF CHAR): LONGCARD;

(* given the var name in this instance - remove any prefix stuff and
   save.  This will allow a variable to have a record qualifier or
   a pointer to the variable.


   e.g.   RecName.Varname  (save the "RecName." return ID for Varname)
          Point^Varname   (save the "Point^" return ID for Varname)
          Rec.Point^.Varname (save the "Rec.Point^." return ID for Varname)


   Expressions are not allowed - (e.g. VarName1 + VarName2 )
      John - Maybe you could fix this
*)

CONST

  PrefixSet = CharSet{'^','.'};


VAR J : CARDINAL;
    Prefix : ARRAY[0..30] OF CHAR;
    TmpStr : ARRAY[0..40] OF CHAR;

BEGIN

 J := Length(VarName);
 Fill(ADR(Prefix),SIZE(Prefix),0);  (* insure no residule junk*)
 IF J = 0
   THEN  RETURN 0;
   END;


 LOOP
   IF VarName[J] IN PrefixSet   (* prefix exists - save *)
     THEN
       Slice(Prefix,VarName,0,J+1);
       Slice(TmpStr,VarName,J+1,Length(VarName));
       EXIT;
     END;
   DEC(J);
   IF J = 0
     THEN
       Copy(TmpStr,VarName);
       EXIT;
     END;
 END; (* end of loop *)

 J := 1;
 LOOP
   IF Compare(ProgVars.Vars[J].Name, TmpStr) = 0
     THEN EXIT;
     END;
   INC(J);
   IF J > MaxVars   (* the var wasn't found - assume sqlda in a statement *)
     THEN AddHostVar(TmpStr,0,0,FALSE);  (* was not found in declare section*)
          RETURN GetID(VarName);
          EXIT;
     END;
 END;
 Copy(ProgVars.Vars[J].Prefix,Prefix);  (* save prefix for subsequent getvar name*)
 RETURN LONGCARD(J);
END GetID;

PROCEDURE GetVarName(VAR VarName : ARRAY OF CHAR;
                     VAR type,len : CARDINAL;
                         ID : LONGCARD);
VAR
  J : CARDINAL;
BEGIN
  J := CARDINAL(ID);
  Copy(VarName,ProgVars.Vars[J].Prefix);
  Append(VarName,ProgVars.Vars[J].Name);
  Append(VarName,ProgVars.Vars[J].Suffix);
  type := ProgVars.Vars[J].Type;
  len  := ProgVars.Vars[J].Len
END GetVarName;


PROCEDURE SQLStatement(Line : ARRAY OF CHAR): BOOLEAN;
(* return true if line contains EXEC SQL *)

BEGIN
  IF (Pos(Line,'EXEC SQL') < MAX(CARDINAL))
    THEN RETURN TRUE
    ELSE RETURN FALSE;
  END;

END SQLStatement;


PROCEDURE PrepareSQL(VAR Line : ARRAY OF CHAR; VAR Token: SQLPREP.sqla_tokens);
(* parse the sql statement and fill the  Token with any host variables *)
VAR
  NbrTokens: CARDINAL;
  J,K : CARDINAL;
  Str : ARRAY[0..30] OF CHAR;
BEGIN
  NbrTokens := 0;
  Subst(Line,'EXEC SQL','  ');  (* get rid of the exec sql part of line*)
  Subst(Line,';',' ');          (* get rid of ';' *)

  J := 0;
  LOOP
    J := NextPos(Line,':',J);
    IF J = MAX(CARDINAL)
      THEN Token.Header.used := LONGCARD(NbrTokens);
           EXIT;
      END;
   INC(J);
   K := 0;
   Fill(ADR(Str),SIZE(Str),0);

    LOOP

      IF NOT (Line[J] IN TermSet)
        THEN
          Str[K] := Line[J];
          Line[J] := ' ';
          INC(J);
          INC(K);
        ELSE    (* end of get var *)
          EXIT;
       END;
    END;
    INC(NbrTokens);
    Token.Tokens[NbrTokens].tokenID := GetID(Str);
  END;

(* get rid of any non sql characters (LF/CR tab etc); *)
 FOR J := 0 TO Length(Line)-1 DO
   IF NOT (Line[J] IN SQLChars)
     THEN
       Line[J] := ' ';
     END;

 END;


END PrepareSQL;


PROCEDURE AssignM2Type(Nbr : CARDINAL;
                       Name,Suffix : ARRAY OF CHAR; SNbr : CARDINAL; L : CARDINAL);
BEGIN
  WITH M2Types[Nbr] DO
    Copy(M2Type,Name);
    Copy(ObjectSuffix,Suffix);
    SqlNbr := SNbr;
    M2Len := L;
  END;
END AssignM2Type;





BEGIN   (* initialization code *)
  Fill(ADR(M2Types),SIZE(M2Types),0);
  Fill(ADR(ProgVars),SIZE(ProgVars),0);
  Location := 0;
  AssignM2Type(0,'LONGREAL','',480,8);
  AssignM2Type(1,'CHAR','',460,1);        (* Assume var length char *)
  AssignM2Type(2,'CARDINAL','',500,2);
  AssignM2Type(3,'LONGCARD','',496,4);
  AssignM2Type(4,'INTEGER','',500,2);
  AssignM2Type(5,'LONGINT','',496,4);
  AssignM2Type(6,'BYTE','',452,1);
  AssignM2Type(7,'BOOLEAN','',452,1);
  AssignM2Type(8,'REAL','',480,4);
  AssignM2Type(9,'FCHAR','',500,1);        (* fixed length char *)
  AssignM2Type(10,'Date','',384,10);
  AssignM2Type(11,'Time','',388,8);
  AssignM2Type(12,'TimeStamp','',392,26);
  AssignM2Type(13,'LongVChar','',456,SIZE(LongVChar));

(* SQL Objects that are supported *)

  AssignM2Type(14,'RealObj','.LR',480,8);
  AssignM2Type(15,'CHAR','',460,1);        (* Assume var length char *)
  AssignM2Type(16,'CardObj','.Card',500,2);
  AssignM2Type(17,'LongIntObj','.LI',496,4);
  AssignM2Type(18,'BoolObj','.B',452,1);
  AssignM2Type(19,'FcharObj','.DataPnt',500,1);        (* fixed length char *)
  AssignM2Type(20,'DateObj','.D',384,10);
  AssignM2Type(21,'TimeObj','.TM',388,8);
  AssignM2Type(22,'TStmpObj','.TS',392,26);
  AssignM2Type(23,'MLEObj','.DataPnt',456,SIZE(LongVChar));

END ParseVar.


