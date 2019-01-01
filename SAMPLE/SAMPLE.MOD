IMPLEMENTATION MODULE Sample;
FROM Lists IMPORT Element,GenList;
FROM IO IMPORT WrStrRedirect;
FROM FormIO IMPORT WrF,WrF1,WrF2,WrF3,WrF4,WrF5;
FROM Str IMPORT Copy;


IMPORT SQLPREP;


(****
EXEC SQL INCLUDE SQLDA;
***)
(***** included by precompiler *)
FROM SQLDA IMPORT sqlda,sqldaPtr;
FROM SQLCA IMPORT sqlca;
FROM SQLStuff IMPORT AllocSQLDA, DeallocSQLDA,SQLErrorHandler;
CONST
xxProgName = CHR(111) +CHR(65) +CHR(65) +CHR(66) +CHR(65) +CHR(68) +CHR(67) +CHR(67) +
        CHR(69) +CHR(68) +CHR(32) +CHR(32) +CHR(32) +CHR(32) +CHR(32) +CHR(32) +
        CHR(115) +CHR(97) +CHR(109) +CHR(112) +CHR(108) +CHR(101) +CHR(32) +CHR(32) +
        CHR(106) +CHR(66) +CHR(90) +CHR(73) +CHR(80) +CHR(67) +CHR(75) +CHR(73) +
        CHR(48) +CHR(32) +CHR(32) +CHR(32) +CHR(32) +CHR(32) +CHR(32) +CHR(32);
VAR 
  SQLca : sqlca; (* communications area*)
  SQLda : sqldaPtr; (* data area (if needed ) *)
  RC    : CARDINAL;


VAR
  StaffRec : Staff;
  OrgRec   : Org;


PROCEDURE CopyDisplay(Line : ARRAY OF CHAR);
(* intercept the WrFx calls an place in the global display line*)
BEGIN
 Copy(DispLine,Line);
END CopyDisplay;



CLASS IMPLEMENTATION Org;
  (******************************************************)
  (*   SQL CURSORS TO SUPPORT THE CLASS	                *)
  (******************************************************)

(****
  EXEC SQL DECLARE GetOrgLst CURSOR FOR
    SELECT * FROM ORG;
***)

(****
  EXEC SQL DECLARE GetStaffLst CURSOR FOR
    SELECT * FROM Staff
    WHERE Dept=:DeptNbr;
***)

(****
  EXEC SQL DECLARE GetOrg CURSOR FOR
    SELECT * FROM Org
    WHERE DeptNumb = :DeptNbr;
***)

(****
  EXEC SQL DECLARE GetStats CURSOR FOR
    SELECT AVG(Salary), MIN(Salary),
           MAX(Salary),SUM(Salary)
    FROM Staff
    WHERE Dept = :DeptNbr;
***)


  PROCEDURE GetStaffList();
  VAR AStaff : Staff;
  BEGIN
(****
    EXEC SQL OPEN  GetStaffLst;
***)
  RC := SQLPREP.SQLASTRT(ADR(xxProgName),NIL,SQLca); (* get semaphore*)
  RC := SQLPREP.SQLAALOC(1,1,1,NIL);
    RC :=SQLPREP.SQLASETV(1,0,500,2,ADR(DeptNbr),NIL,NIL);

  RC := SQLPREP.SQLACALL(26,2,1,0,NIL); 
  RC := SQLPREP.SQLASTOP(NIL);(* release semephore*)
    IF StaffLst.Initialized()
      THEN StaffLst.Dispose
      ELSE StaffLst.Initialize('');
    END;
    WITH AStaff DO
        SQLca.sqlcode := 0;
    	WHILE SQLca.sqlcode = 0 DO
(****
          	EXEC SQL FETCH GetStaffLst INTO
            	:ID,:Name :NameNul,:DeptNbr :DeptNul,:Job :JobNul,:Years:YearNul,
    		:Salary:SalNul,:Comm:ComNul;
***)
  RC := SQLPREP.SQLASTRT(ADR(xxProgName),NIL,SQLca); (* get semaphore*)
  RC := SQLPREP.SQLAALOC(2,7,2,NIL);
    RC :=SQLPREP.SQLASETV(2,0,500,2,ADR(ID),NIL,NIL);
    RC :=SQLPREP.SQLASETV(2,1,461,15,ADR(Name),ADR(NameNul),NIL);
    RC :=SQLPREP.SQLASETV(2,2,501,2,ADR(DeptNbr),ADR(DeptNul),NIL);
    RC :=SQLPREP.SQLASETV(2,3,461,11,ADR(Job),ADR(JobNul),NIL);
    RC :=SQLPREP.SQLASETV(2,4,501,2,ADR(Years),ADR(YearNul),NIL);
    RC :=SQLPREP.SQLASETV(2,5,481,8,ADR(Salary),ADR(SalNul),NIL);
    RC :=SQLPREP.SQLASETV(2,6,481,8,ADR(Comm),ADR(ComNul),NIL);

  RC := SQLPREP.SQLACALL(25,2,0,2,NIL); 
  RC := SQLPREP.SQLASTOP(NIL);(* release semephore*)
    		AStaff.MakeDisplayLine();
           	StaffLst.AddElmt(AStaff);
    	END;
(****
    	EXEC SQL CLOSE GetStaffLst;
***)
  RC := SQLPREP.SQLASTRT(ADR(xxProgName),NIL,SQLca); (* get semaphore*)
  RC := SQLPREP.SQLACALL(20,2,0,0,NIL); 
  RC := SQLPREP.SQLASTOP(NIL);(* release semephore*)
    END; (* with astaff *)
(****
    EXEC SQL OPEN GetStats;
***)
  RC := SQLPREP.SQLASTRT(ADR(xxProgName),NIL,SQLca); (* get semaphore*)
  RC := SQLPREP.SQLAALOC(3,1,3,NIL);
    RC :=SQLPREP.SQLASETV(3,0,500,2,ADR(DeptNbr),NIL,NIL);

  RC := SQLPREP.SQLACALL(26,4,3,0,NIL); 
  RC := SQLPREP.SQLASTOP(NIL);(* release semephore*)
(****
    EXEC SQL FETCH GetStats INTO
         :AvgSalary,:MinSalary,:MaxSalary,:TotalSalary;
***)
  RC := SQLPREP.SQLASTRT(ADR(xxProgName),NIL,SQLca); (* get semaphore*)
  RC := SQLPREP.SQLAALOC(4,4,4,NIL);
    RC :=SQLPREP.SQLASETV(4,0,480,8,ADR(AvgSalary),NIL,NIL);
    RC :=SQLPREP.SQLASETV(4,1,480,8,ADR(MinSalary),NIL,NIL);
    RC :=SQLPREP.SQLASETV(4,2,480,8,ADR(MaxSalary),NIL,NIL);
    RC :=SQLPREP.SQLASETV(4,3,480,8,ADR(TotalSalary),NIL,NIL);

  RC := SQLPREP.SQLACALL(25,4,0,4,NIL); 
  RC := SQLPREP.SQLASTOP(NIL);(* release semephore*)
(****
    EXEC SQL CLOSE GetStats;
***)
  RC := SQLPREP.SQLASTRT(ADR(xxProgName),NIL,SQLca); (* get semaphore*)
  RC := SQLPREP.SQLACALL(20,4,0,0,NIL); 
  RC := SQLPREP.SQLASTOP(NIL);(* release semephore*)

  END GetStaffList;

  PROCEDURE MakeDisplayLine();

  BEGIN
    WrF4('%3u  %12s  %12s  %18s',DeptNbr,DeptName,Division,Location  );
    Assign(DispLine);
  END MakeDisplayLine;

BEGIN
END Org;  (* end class implementation org *)

(* utility to read org table *)

  PROCEDURE GetOrgLst(VAR TheList : GenList);
  VAR OrgUnit : Org;
  BEGIN
(****
    EXEC SQL OPEN GetOrgLst;
***)
  RC := SQLPREP.SQLASTRT(ADR(xxProgName),NIL,SQLca); (* get semaphore*)
  RC := SQLPREP.SQLACALL(26,1,0,0,NIL); 
  RC := SQLPREP.SQLASTOP(NIL);(* release semephore*)
    IF TheList.Initialized()
      THEN TheList.DisposeList;
      ELSE TheList.InitList;
    END;
    SQLca.sqlcode := 0;
    WHILE SQLca.sqlcode = 0 DO
      WITH OrgUnit DO
(****
      EXEC SQL FETCH GetOrgLst INTO
       :DeptNbr,:DeptName,:Manager,:Division,
       :Location;
***)
  RC := SQLPREP.SQLASTRT(ADR(xxProgName),NIL,SQLca); (* get semaphore*)
  RC := SQLPREP.SQLAALOC(5,5,5,NIL);
    RC :=SQLPREP.SQLASETV(5,0,500,2,ADR(DeptNbr),NIL,NIL);
    RC :=SQLPREP.SQLASETV(5,1,460,41,ADR(DeptName),NIL,NIL);
    RC :=SQLPREP.SQLASETV(5,2,500,2,ADR(Manager),NIL,NIL);
    RC :=SQLPREP.SQLASETV(5,3,460,31,ADR(Division),NIL,NIL);
    RC :=SQLPREP.SQLASETV(5,4,460,31,ADR(Location),NIL,NIL);

  RC := SQLPREP.SQLACALL(25,1,0,5,NIL); 
  RC := SQLPREP.SQLASTOP(NIL);(* release semephore*)
      END;
      OrgUnit.MakeDisplayLine();
      TheList.AddItem(OrgUnit);

    END;
(****
    EXEC SQL CLOSE getOrgLst;
***)
  RC := SQLPREP.SQLASTRT(ADR(xxProgName),NIL,SQLca); (* get semaphore*)
  RC := SQLPREP.SQLACALL(20,1,0,0,NIL); 
  RC := SQLPREP.SQLASTOP(NIL);(* release semephore*)
  END GetOrgLst;




CLASS IMPLEMENTATION Staff;

  PROCEDURE MakeDisplayLine();

  BEGIN
    WrF5('%12s  %4s  %4u  %8.2r,  %8.2r',Name,Job, Years,Salary,Comm );
    Assign(DispLine);
  END MakeDisplayLine;

BEGIN
END Staff;   (* end class implementation staff *)


(* initialization code*)

BEGIN
  WrStrRedirect := CopyDisplay;   (* redirect output to copy display*)
END Sample.


