(*#debug (vid =>off) *)
IMPLEMENTATION MODULE LstBox;

(*FROM GenLists IMPORT GenList,GetElmt,DisposeList,
     ListLength,NewList,ListInsert,StrCode,GetElmtAdr,ListDelete; *)
FROM Lists IMPORT Element,GenList,ElmtPntr;
FROM OS2DEF IMPORT HWND;
FROM FIO IMPORT Exists,Open,RdStr,IOresult,Close,File;
FROM Str IMPORT Copy,Append,Pos,Length;


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

CLASS IMPLEMENTATION DropDownList;
PROCEDURE AddElmt(VAR TheElmt : Element;Size : CARDINAL);
BEGIN
   ItemList.AddItem(TheElmt,Size);
END AddElmt;

 PROCEDURE Initialize(FileName : ARRAY OF CHAR);
 VAR
   Error : CARDINAL;
   F : File;
   Str : ARRAY [0..80] OF CHAR;
   E : StrElmt;
 BEGIN
 (*  NewList(ItemList);*)
   ItemList.InitList;
   IF Exists(FileName)
     THEN
        F := Open(FileName);
        REPEAT
          RdStr(F,Str);
          E.Assign(Str);
          ItemList.AddItem(E,SIZE(E));
        UNTIL Str[0] = 0C;
        Close(F);
        (* Error := TextFileToList(FileName,ItemList); *)
     END;
   init := 12345;
 END Initialize;



PROCEDURE AddScrItem( Str : ARRAY OF CHAR);
 VAR
    Reply : Win.MRESULT;
    P1,P2 : Win.MPARAM;
  BEGIN
     P1 := Win.MAKELONG(Win.LIT_END,0);
     P2 := Win.MPARAM(ADR(Str));
     Reply := Win.SendMsg(hwnd, Win.LM_INSERTITEM,P1,P2);

  END AddScrItem;

PROCEDURE DeleteScrItem(ItemNbr : CARDINAL);
VAR
    Reply : Win.MRESULT;
    P1,P2 : Win.MPARAM;
  BEGIN
     P1 := Win.MAKELONG(ItemNbr,0);
     P2 := 0;
     Reply := Win.SendMsg(hwnd, Win.LM_DELETEITEM,P1,P2);
END DeleteScrItem;

PROCEDURE ClearItemScr();
 VAR
    Reply : Win.MRESULT;
    P1,P2 : Win.MPARAM;
  BEGIN
     P1 := 0;
     P2 := 0;
     Reply := Win.SendMsg(hwnd, Win.LM_DELETEALL,P1,P2);

END ClearItemScr;


PROCEDURE SelectFirst();
VAR
     Reply : Win.MRESULT;
    P1,P2 : Win.MPARAM;
BEGIN
   P1 := 0;
   P2 := Win.MAKELONG(ORD(TRUE),0);
   Reply := Win.SendMsg(hwnd, Win.LM_SELECTITEM,P1,P2);

END SelectFirst;

 PROCEDURE SetSelected(J : CARDINAL);
 VAR
    Reply : Win.MRESULT;
    P1,P2 : Win.MPARAM;
 BEGIN
   P1 := Win.MAKELONG(J-1,0);
   P2 := Win.MAKELONG(ORD(TRUE),0);
   Reply := Win.SendMsg(hwnd, Win.LM_SELECTITEM,P1,P2);


 END SetSelected;

 PROCEDURE FillBox(ParentHwnd : HWND; ControlID : CARDINAL);
 VAR
   J,Code : CARDINAL;
   Str : ARRAY[0..100] OF CHAR;
   E : POINTER TO StrElmt;


 BEGIN
   Parent := ParentHwnd;
   Id := ControlID;
   hwnd := Win.WindowFromID(ParentHwnd,ControlID);
   FOR J := 1 TO ItemList.ListLength() DO
     ItemList.GetItemAdr(E,J);
     E^.GetStr(Str);
     AddScrItem(Str);
   END;
   SelectFirst();
 END FillBox;

  PROCEDURE GetSelectedAdr(VAR  ObjPnt : ElmtPntr;
                        VAR ItemNbr : CARDINAL);
  VAR
    Reply : Win.MRESULT;
    P1,P2 : Win.MPARAM;
    Size,Code  : CARDINAL;
  BEGIN
    Reply := Win.SendMsg(hwnd,Win.LM_QUERYSELECTION, P1,P2);
    IF Reply <> Win.LIT_NONE
      THEN
        ItemList.GetItemAdr(ObjPnt,CARDINAL(Reply+1));
        ItemNbr := CARDINAL(Reply);
    END;

  END GetSelectedAdr;

  PROCEDURE GetSelected(VAR  Object : Element;
                        VAR ItemNbr : CARDINAL);
  VAR
    Reply : Win.MRESULT;
    P1,P2 : Win.MPARAM;
    Size,Code  : CARDINAL;
  BEGIN
    Reply := Win.SendMsg(hwnd,Win.LM_QUERYSELECTION, P1,P2);
    IF Reply <> Win.LIT_NONE
      THEN
        ItemList.GetItem(Object,CARDINAL(Reply+1));
        ItemNbr := CARDINAL(Reply);
    END;

  END GetSelected;

 PROCEDURE GetItemSize(Spot : CARDINAL):CARDINAL;
 BEGIN
   RETURN ItemList.GetItemSize(Spot);
 END GetItemSize;

 PROCEDURE ReadBox( VAR Value : ARRAY OF CHAR);
 VAR
   ObjPnt : POINTER TO StrElmt;
   J : CARDINAL;
 BEGIN
   GetSelectedAdr(ObjPnt,J);
   ObjPnt^.GetStr(Value);
 END ReadBox;

 PROCEDURE Initialized() : BOOLEAN;
 BEGIN
   RETURN init = 12345;
 END Initialized;

 PROCEDURE Dispose();
 BEGIN
   ItemList.DisposeList();
   init := 0;
 END Dispose;

BEGIN
END DropDownList;

(***********************************************************************)
(*  uses most of the items in the drop down list                       *)
(***********************************************************************)

CLASS IMPLEMENTATION ListBox;

    (* on double click get the address of the selected *)

 PROCEDURE DeleteItem(ItemNbr : CARDINAL);

 BEGIN
    ItemList.DeleteItem(ItemNbr);
 END DeleteItem;



      (* on multi select items - return list of selected *)
  PROCEDURE GetSelectedLst( VAR Lst : ListBox);
  BEGIN

  END GetSelectedLst;

  PROCEDURE GetItemAdr(VAR ItemPnt : ElmtPntr;ItemNbr : CARDINAL);
  VAR
    Code,Size : CARDINAL;
  BEGIN
    ItemList.GetItemAdr(ItemPnt,ItemNbr);
  END GetItemAdr;

 PROCEDURE GetItemCnt() : CARDINAL;
 BEGIN

   RETURN ItemList.ListLength();
 END GetItemCnt;


    (* user called routine to fill the genlists with objects *)
  PROCEDURE FillList(VAR TheList : GenList);
  BEGIN
    ItemList := TheList;
  END FillList;


     (* user called routine to get a display line from an object *)
  VIRTUAL PROCEDURE GetDisplayLine(ObjPnt : ADDRESS; VAR Str : ARRAY OF CHAR);

  (* this is the default service if the list is a list of strings *)

  TYPE
    StrPnt = POINTER TO ARRAY[0..100] OF CHAR;
  CONST
    CR =  13C;
  BEGIN

    Copy(Str, StrPnt(ObjPnt)^);  (* Assume string objects *)
    IF Pos(Str,CR) < Length(Str)  (* was not terminated correct *)
      THEN
        Str[Pos(Str,CR)] := 0C;
      END;
  END GetDisplayLine;


                           (*  delete an item from the screen list *)
PROCEDURE DeleteItemScr( ItemNbr : CARDINAL);
END DeleteItemScr;



(* redefinition OF dropdown list - TO also delete the item FROM list*)
PROCEDURE DeleteScrItem(ItemNbr : CARDINAL; ListAlso : BOOLEAN);
BEGIN
  DropDownList.DeleteScrItem(ItemNbr);
  ItemList.DeleteItem(ItemNbr + 1);
END DeleteScrItem;





BEGIN

END ListBox;




END LstBox.

