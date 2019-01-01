MODULE Test;
FROM Sample IMPORT Staff,Org;
FROM Lists IMPORT GenList;
FROM LstBox IMPORT ListBox;
FROM Sample IMPORT GetOrgLst;
FROM SQLEnv IMPORT SQLGSTRD;
FROM Str IMPORT Length,Copy;
FROM SQLCA IMPORT sqlca;
IMPORT SAM;

   (* presentation manager junk *)

(*# call(same_ds => off) *)
(*# data(heap_size=> 3000) *)


IMPORT OS2DEF,Win,Lib,SYSTEM;

FROM OS2DEF IMPORT HDC,HRGN,HAB,HPS,HBITMAP,HWND,HMODULE,HSEM,
                   POINTL,RECTL,PID,TID,LSET,NULL,
                   COLOR,NullVar,NullStr,BOOL ;

CONST
  WindowId = 255;

VAR
  Hab       : HAB;
  Hps       : HPS;
  BackColor : COLOR;
  ForeColor : COLOR;
  ChangeBack: BOOLEAN;



  (********************* application stuff *)
  StaffObj : Staff;
  OrgObj   : Org;
  OrgList  : ListBox;
  DBName   : ARRAY[0..20] OF CHAR;
  SQLca    : sqlca;
  RC : CARDINAL;



PROCEDURE Setup();

BEGIN
  Copy(DBName,'SAMPLE');
  RC := SQLGSTRD(0,Length(DBName),'S',SQLca,NIL,DBName); (* start the database*)
  GetOrgLst(OrgList.ItemList);
END Setup;







(*--------------------  Start of window procedure  ---------------------*)
(*# save,
    call(near_call=>off, reg_param=>(), reg_saved=>(di,si,ds,es,st1,st2)) *)
PROCEDURE WindowProc(hwnd : HWND;msg:CARDINAL;mp1,mp2:Win.MPARAM):Win.MRESULT;
 (* this main window will only call the dialogs on the create *)
 (* and will wait for the end message from the system menu    *)
VAR
  C : CARDINAL;
  Reply : Win.MRESULT;
BEGIN
  CASE msg OF
  | Win.WM_CREATE:Setup();  (* read the database *)
                   C := Win.DlgBox(Win.HWND_DESKTOP, Win.HWND_DESKTOP, SAM.SampleMessageProc,
			            0, SAM.OrgLst, ADR(OrgList));
			       Reply := Win.SendMsg(hwnd,Win.DID_CANCEL,mp1,mp2);
			               (* when done with org unit - done with everything*)
			


  | Win.WM_CLOSE:

      (*----------------------------------------------------------------*)
      (* This is the place to put your termination routines             *)
      (*----------------------------------------------------------------*)

      IF NOT Win.PostMsg( hwnd, Win.WM_QUIT, 0, 0 )
       THEN  (* Cause termination        *)
       END;

    ELSE

      (*----------------------------------------------------------------*)
      (* Everything else comes here.  This call MUST exist              *)
      (* in your window procedure.                                      *)
      (*----------------------------------------------------------------*)

      RETURN Win.DefWindowProc( hwnd, msg, mp1, mp2 );
    END;
    RETURN Win.MPARAM(FALSE);

END WindowProc;
(*# restore *)

PROCEDURE Main;
(*****************************************************************
   This procedure is taken from the JPI sample code

******************************************************************)

VAR
  hmq      : Win.HMQ;
  qmsg     : Win.QMSG;
  client   : HWND;
  frame    : HWND;
  createfl : LSET;
  b        : BOOLEAN;
  r        : Win.MRESULT;

BEGIN
  Hab := Win.Initialize( NULL );        (* Initialize PM                *)
  hmq := Win.CreateMsgQueue( Hab, 0 );  (* Create a message queue       *)

  IF NOT Win.RegisterClass(             (* Register window class        *)
     Hab,                               (* Anchor block handle          *)
     FarADR("Datamanager"),                (* Window class name            *)
     WindowProc,                        (* Address of window procedure  *)
     0,                                 (* No special Class Style       *)
     0                                  (* No extra window words        *)
     ) THEN END;

  createfl := Win.FCF_TITLEBAR+
              Win.FCF_MINMAX+Win.FCF_SYSMENU +
              Win.FCF_SHELLPOSITION+
              Win.FCF_TASKLIST+
              Win.FCF_SIZEBORDER;         (* Set Frame Control Flag       *)

  frame := Win.CreateStdWindow(
               Win.HWND_DESKTOP,        (* Desktop window is parent     *)
               Win.FS_TASKLIST+Win.WS_VISIBLE,         (* Class Style                  *)
               createfl,                (* Frame control flag           *)
               FarADR("Datamanager"),      (* Client window class name     *)
               'JPI MOD2 IBM Datamanager SQL Demo',(* Title                    *)
               0,                       (* No special class style       *)
               NULL,                    (* Resource is in .EXE file     *)
               WindowId,                (* Frame window identifier      *)
               client                   (* Client window handle         *)
               );


(*
  IF NOT Win.SetWindowPos( frame,       (* Set the size and position of *)
                   Win.HWND_TOP,        (* the window before showing.   *)
                   0, 0, 500, 500,
                   Win.SWP_SIZE+Win.SWP_MOVE+Win.SWP_ACTIVATE+Win.SWP_SHOW
                 ) THEN END;
*)
(*----------------------------------------------------------------------*)
(* Get and dispatch messages from the application message queue         *)
(* until WinGetMsg returns FALSE, indicating a WM_QUIT message.         *)
(*----------------------------------------------------------------------*)
  WHILE( Win.GetMsg( Hab, qmsg, HWND(NULL), 0, 0 ) ) DO
    r := Win.DispatchMsg( Hab, qmsg );
  END;

  IF NOT Win.DestroyWindow( frame ) THEN      (* Tidy up...                   *)
      END;
  IF NOT Win.DestroyMsgQueue( hmq ) THEN      (* and                          *)
      END;
  IF NOT Win.Terminate( Hab ) THEN            (* terminate the application    *)
     END;

END Main;
(*----------------------  End of main procedure  -----------------------*)


BEGIN
  Main();
END Test.
