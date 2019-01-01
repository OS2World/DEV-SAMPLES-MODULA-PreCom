IMPLEMENTATION MODULE SAM;
FROM LstBox IMPORT ListBox;
FROM Sample IMPORT Org,Staff;
FROM Str IMPORT FixRealToStr,CardToStr;
(* sample data manager application *)

IMPORT OS2DEF,Win,Lib,SYSTEM;

FROM OS2DEF IMPORT HDC,HRGN,HAB,HPS,HBITMAP,HWND,HMODULE,HSEM,
                   POINTL,RECTL,PID,TID,LSET,NULL,
                   COLOR,NullVar,NullStr,BOOL ;


VAR

 OrgList  : POINTER TO ListBox;
 OrgUnit  : POINTER TO Org;
 StaffMbr : POINTER TO Staff;
(*# save,
    call(near_call=>off, reg_param=>(), reg_saved=>(di,si,ds,es,st1,st2)) *)





PROCEDURE WrTxtItem(hwnd : HWND; Id : CARDINAL; Txt : ARRAY OF CHAR);
VAR
  B : BOOLEAN;
BEGIN
  B := Win.SetWindowText(Win.WindowFromID(hwnd,Id),Txt);
END WrTxtItem;

PROCEDURE WrRealItem(hwnd : HWND; Id : CARDINAL; R : LONGREAL);
VAR
  Txt : ARRAY[0..14] OF CHAR;
  B : BOOLEAN;
BEGIN
  FixRealToStr(R,2,Txt,B);
  WrTxtItem(hwnd,Id,Txt);
END WrRealItem;

PROCEDURE WrCardItem(hwnd : HWND; Id : CARDINAL; C : CARDINAL);
VAR
  Txt : ARRAY[0..12] OF CHAR;
  B : BOOLEAN;
BEGIN
  CardToStr(LONGCARD(C),Txt,10,B);
  WrTxtItem(hwnd,Id,Txt);
END WrCardItem;



PROCEDURE StaffDlgProc(hwnd : HWND;msg:CARDINAL;mp1,mp2:Win.MPARAM):Win.MRESULT;

VAR Nbr : CARDINAL;
   A   : ADDRESS;
BEGIN
  CASE msg OF
    Win.WM_INITDLG:
                    WrTxtItem(hwnd,Name,StaffMbr^.Name);
                    WrTxtItem(hwnd,Job,StaffMbr^.Job);
                    WrCardItem(hwnd,Dept,StaffMbr^.DeptNbr);

                    WrCardItem(hwnd,Years, StaffMbr^.Years);
                    WrRealItem(hwnd,Salary,StaffMbr^.Salary);
                    WrRealItem(hwnd,Commis,StaffMbr^.Comm);


   |Win.WM_CONTROL:
         CASE Win.LOWORD(mp1) OF


        END; (* end case of control ID *)
   (* process any push buttons or other control windows *)
   |Win.WM_COMMAND:
   |Win.WM_CLOSE:
         Win.PostMsg(hwnd, Win.WM_COMMAND, Win.MAKELONG(Win.DID_CANCEL,0), 0);
    ELSE RETURN(Win.DefDlgProc(hwnd, msg, mp1, mp2));
 END; (* end of outer case *)
 RETURN Win.DefDlgProc(hwnd,msg,mp2,mp2);
END StaffDlgProc;


PROCEDURE OrgUnitDlgProc(hwnd : HWND;msg:CARDINAL;mp1,mp2:Win.MPARAM):Win.MRESULT;

VAR Nbr : CARDINAL;
    A  : LONGCARD;
    B  : BOOLEAN;

BEGIN
  CASE msg OF
    Win.WM_INITDLG: A := 5555;
                    B := Win.SetWindowULong(hwnd,0,A);
                    A := 0;
                    A := Win.QueryWindowULong(hwnd,0);
                    OrgUnit^.GetStaffList();
                    OrgUnit^.StaffLst.FillBox(hwnd,EmplyeeLst);
                    WrTxtItem(hwnd,Department,OrgUnit^.DeptName);
                    WrCardItem(hwnd,DeptNbr,OrgUnit^.DeptNbr);

                    WrCardItem(hwnd,Manager, OrgUnit^.Manager);
                    WrTxtItem(hwnd,Division,OrgUnit^.Division);
                    WrTxtItem(hwnd,Location,OrgUnit^.Location);
                    WrRealItem(hwnd,Avg,OrgUnit^.AvgSalary);
                    WrRealItem(hwnd,Min,OrgUnit^.MinSalary);
                    WrRealItem(hwnd,Max,OrgUnit^.MaxSalary);

   |Win.WM_CONTROL:
         CASE Win.LOWORD(mp1) OF
           EmplyeeLst :   (* if an employee was selected from the list*)
                  CASE Win.HIWORD(mp1) OF (* double click set active *)
                    Win.LN_ENTER:OrgUnit^.StaffLst.GetSelected(StaffMbr,Nbr);
                                  Nbr := Win.DlgBox(Win.HWND_DESKTOP, hwnd,
                                           StaffDlgProc,
			                               0, EmplyDetail,NIL);
				  END;	

        END; (* end case of control ID *)
   (* process any push buttons or other control windows *)
   |Win.WM_COMMAND:
   |Win.WM_CLOSE:
         Win.PostMsg(hwnd, Win.WM_COMMAND, Win.MAKELONG(Win.DID_CANCEL,0), 0);
    ELSE RETURN(Win.DefDlgProc(hwnd, msg, mp1, mp2));
 END; (* end of outer case *)
 RETURN Win.DefDlgProc(hwnd,msg,mp2,mp2);
END OrgUnitDlgProc;

PROCEDURE SampleMessageProc(hwnd : HWND;msg:CARDINAL;mp1,mp2:Win.MPARAM):Win.MRESULT;
VAR

 hWndParent : HWND;
 J,Size,Code : CARDINAL;
 P1,P2 : Win.MPARAM;
 Reply : Win.MRESULT;
 ScrollHwnd : HWND;
 Nbr : CARDINAL;

BEGIN
  CASE msg OF
    Win.WM_INITDLG: OrgList := ADDRESS(mp2);
                  OrgList^.FillBox(hwnd,OrgUnitLst);
   |Win.WM_CONTROL:
         CASE Win.LOWORD(mp1) OF
           OrgUnitLst :
                  CASE Win.HIWORD(mp1) OF (* double click set active *)
                    Win.LN_ENTER: OrgList^.GetSelected(OrgUnit,Nbr);
                                  Nbr := Win.DlgBox(Win.HWND_DESKTOP, hwnd,
                                           OrgUnitDlgProc,
			                               0, OrgUnitDetail,OrgUnit);
				  END;	

        END; (* end case of control ID *)
   (* process any push buttons or other control windows *)
   |Win.WM_COMMAND:
(**********
     CASE Win.LOWORD(mp1) OF
            ZID.PB_OK: (* an ok button was pushed    *)
                 Reply := Win.SendMsg(Win.WindowFromID(hwnd,ZID.LB_RECENT),
                                      Win.LM_QUERYSELECTION, P1,P2);
                 IF Reply <> Win.LIT_NONE
                   THEN
                     GetElmtAdr(MemoryList,CARDINAL(Reply+1),Pnt,Size,Code);
                     CurtClient^ := Pnt^;
                     AddToMemory();
                     (* WrZpersonaScr(MainHwnd,CurtClient); BDC 07/08/92 *)
					  WrScreen();

                   END;
                 Win.DismissDlg(hwnd, 0);

            |ZID.PB_CANCEL: (* Cancle Button            *)
                 Win.DismissDlg(hwnd, 1);
            ELSE RETURN Win.DefDlgProc(hwnd,Message,mp2,mp2);
         END; (* end of push button commands *)

******************)
   |Win.WM_CLOSE:
         Win.PostMsg(hwnd, Win.WM_COMMAND, Win.MAKELONG(Win.DID_CANCEL,0), 0);
    ELSE RETURN(Win.DefDlgProc(hwnd, msg, mp1, mp2));
 END; (* end of outer case *)
 RETURN Win.DefDlgProc(hwnd,msg,mp2,mp2);
END SampleMessageProc;




(*# restore *)



END SAM.