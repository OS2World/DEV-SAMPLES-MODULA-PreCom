(*#debug (vid =>off) *)
IMPLEMENTATION MODULE Lists;
FROM Storage IMPORT ALLOCATE,DEALLOCATE;
FROM Lib IMPORT Move;
FROM FIO IMPORT Exists,Open,RdStr,IOresult,Close,File,EOF;
FROM Str IMPORT Copy;


CLASS IMPLEMENTATION Element;
(*  VIRTUAL PROCEDURE Compare ( P : ElmtPntr) : BOOLEAN;
  BEGIN
    RETURN TRUE;
  END Compare;
*)
BEGIN
END Element;

CLASS IMPLEMENTATION StrElmt;
  PROCEDURE Assign(AString : ARRAY OF CHAR);
  BEGIN
    Copy(TheStr,AString);
  END Assign;

  PROCEDURE GetStr(VAR AString : ARRAY OF CHAR);
  BEGIN
    Copy(AString,TheStr);
  END GetStr;
BEGIN
END StrElmt;




CLASS IMPLEMENTATION GenList;
  PROCEDURE InitList;
  BEGIN
    First := NIL;
    Last  := NIL;
    Now   := NIL;
    Type[0]  := 0C;
    NbrInLst := 0;
    NowNbr   := 0;
  END InitList;


  PROCEDURE ListLength():CARDINAL;
  BEGIN
   RETURN NbrInLst;
  END ListLength;

  PROCEDURE Initialized(): BOOLEAN;
  BEGIN
    RETURN (First <> NIL);
  END Initialized;


  PROCEDURE DisposeList;
  VAR
    J , K : CARDINAL;
  BEGIN
   K := NbrInLst;
   Now := First;
   WHILE Now # NIL DO
     First := Now^.Next;
     DEALLOCATE(Now,Now^.ElmtSize);
     Now := First;
   END;
   NbrInLst := 0;
   NowNbr := 0;
   First := NIL;
   Last  := NIL;
   Now   := NIL;
  END DisposeList;

  PROCEDURE MoveToSpot(Spot : CARDINAL);
  VAR J : CARDINAL;
  BEGIN

    IF Spot >= NbrInLst
      THEN
        Now := Last;
        NowNbr := NbrInLst;
        RETURN;
      END;
    IF Spot < NowNbr
      THEN
        Now := First;
        NowNbr := 1;
      END;
    WHILE NowNbr < Spot DO
      INC(NowNbr);
      Now := Now^.Next;
    END;

  END MoveToSpot;

  PROCEDURE GetItemSize(Spot : CARDINAL):CARDINAL;
  BEGIN
   IF NbrInLst = 0
     THEN RETURN 0;
     END;
   MoveToSpot(Spot);
   RETURN Now^.ElmtSize;
  END GetItemSize;

  PROCEDURE AddItem(VAR Item : Element; Size : CARDINAL);  (* always stick at end *)
  VAR
    New : ElmtPntr;
  BEGIN
    ALLOCATE(New,Size);
    Move(ADR(Item),New,Size);
    New^.ElmtSize := Size;  (* keep the size for deallocate *)
    New^.Next := NIL;
    New^.Prev := NIL;
    INC(NbrInLst);
    NowNbr := NbrInLst;
    IF First = NIL     (* empty list *)
      THEN
         First := New;
         Last  := New;
         Now   := New;
         RETURN;
      END;
   Last^.Next := New;
   New^.Prev := Last;
   Last := New;
   Now  := New;

  END AddItem;

  PROCEDURE InsertItem(VAR Item : Element; Spot : CARDINAL;Size : CARDINAL);
   VAR
     New : ElmtPntr;
  BEGIN
    IF Spot > NbrInLst  (* simple add to list *)
      THEN AddItem(Item,Size);
      RETURN;
    END;
    ALLOCATE(New,SIZE(Item));
    Move(ADR(Item),New,SIZE(Item));
    New^.ElmtSize := SIZE(Item);  (* keep the size for deallocate *)
    New^.Next := NIL;
    New^.Prev := NIL;
    MoveToSpot(Spot);
    INC(NbrInLst);
    NowNbr := NbrInLst;
    IF Spot = 1   (* special case - insert at beginint *)
      THEN
        New^.Next := First;
        First := New;
      ELSE
        New^.Prev := Now^.Prev;
    END;
    Now^.Prev := New;
    Now := New;
  END InsertItem;

  PROCEDURE DeleteItem(Spot : CARDINAL);
  VAR
    Tmp : ADDRESS;
  BEGIN
    IF NbrInLst = 0
      THEN
        RETURN;  (* empty list - cant delete *)
      END;
    MoveToSpot(Spot);
    DEC(NbrInLst);
    IF Spot = 1  (* delete the first item *)
     THEN
       Now := First;
       First := First^.Next;
       IF First <> NIL   (* IF there is a next item *)
         THEN First^.Prev := NIL; (* SET the prev = NIL *)
         END;
       DEALLOCATE(Now,Now^.ElmtSize);
       Now := First;
       NowNbr := 1;
       RETURN;
    END;
    IF Now = Last   (* delete the last in list *)
      THEN
        Last := Last^.Prev;
        Last^.Next := NIL;
        DEALLOCATE(Now,Now^.ElmtSize);
        Now := Last;
        NowNbr := NbrInLst;
        RETURN;
      END;
                   (* delete from center of list *)
   Tmp := Now^.Next;
   Now^.Next^.Prev := Now^.Prev;
   Now^.Prev^.Next := Now^.Next;
   DEALLOCATE(Now,Now^.ElmtSize);
   Now := Tmp;
  END DeleteItem;

  PROCEDURE GetItem(VAR Item : Element; Spot:CARDINAL);
  BEGIN
    MoveToSpot (Spot);
    Move(Now,ADR(Item),Now^.ElmtSize);
  END GetItem;

  PROCEDURE GetItemAdr(VAR Item : ElmtPntr; Spot: CARDINAL);
  BEGIN
   MoveToSpot(Spot);
  	Item := Now;
  END GetItemAdr;

  PROCEDURE Apply(Proc : ApplyProc);  (* apply procedure to every element*)
  VAR
    EP : ElmtPntr;
    J:CARDINAL;
  BEGIN
    FOR J := 1 TO NbrInLst DO
      GetItemAdr( EP,J);
      Proc(EP);
    END;
  END Apply;

  PROCEDURE FileToList(FileName : ARRAY OF CHAR);
  VAR
   Error : CARDINAL;
   F : File;
   Str : ARRAY [0..200] OF CHAR;
   E : StrElmt;
 BEGIN
   InitList;
   IF Exists(FileName)
     THEN
        F := Open(FileName);
        REPEAT
          RdStr(F,Str);
          E.Assign(Str);
          AddItem(E,SIZE(E));
        UNTIL EOF;
        Close(F);
     END;
  END FileToList;

  PROCEDURE ListToFile(FileName : ARRAY OF CHAR);
  END ListToFile;

BEGIN   (* automatic initialization stuff - constructors *)
    First := NIL;
    Last  := NIL;
    Now   := NIL;
    Type[0]  := 0C;
    NbrInLst := 0;
    NowNbr   := 0;
END GenList;

END Lists.

