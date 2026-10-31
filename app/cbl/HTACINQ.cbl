       IDENTIFICATION DIVISION.
       PROGRAM-ID. HTACINQ.
      ******************************************************************
      * FICTIONAL PROGRAM - SYNTHETIC TRAINING ESTATE - NOT REAL DATA *
      * PROGRAM : HTACINQ - ACCOUNT INQUIRY
      * MAPSET  : HTACMAP   MAP : HTA1
      * DESC    : CICS ONLINE PROGRAM, NON-DATABASE, VSAM FILES ONLY.
      *         : USES EXEC CICS READ/WRITE/REWRITE/DELETE/LINK/XCTL
      *         : AND RETURN. BMS MAP HANDLING WITH DFHAID/DFHBMSCA.
      *         : NO DATABASE CALLS - VSAM FILE CONTROL ONLY. FILE CONTROL ONLY.
      ******************************************************************
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-COMMAREA.
          05 WS-ACCOUNT      PIC X(12).
          05 WS-TO-ACCOUNT   PIC X(12).
          05 WS-AMOUNT       PIC S9(9)V99 COMP-3.
          05 WS-BALANCE      PIC S9(9)V99 COMP-3.
          05 WS-CARD-NO      PIC X(16).
          05 WS-PIN          PIC X(08).
          05 WS-NEW-PIN      PIC X(08).
          05 WS-STATUS       PIC X(08).
          05 WS-MESSAGE      PIC X(60).
          05 WS-SEARCH-KEY   PIC X(20).
          05 WS-MATCH-COUNT  PIC S9(4) COMP VALUE 0.
          05 WS-RESP         PIC S9(8) COMP VALUE 0.
          05 WS-RESP2        PIC S9(8) COMP VALUE 0.
          05 WS-AID          PIC X VALUE SPACE.
          05 WS-EOF          PIC X VALUE 'N'.
          05 WS-FIRST-TIME   PIC X VALUE 'Y'.
          05 WS-EDIT-OK      PIC X VALUE 'Y'.
          05 WS-RETRY-COUNT  PIC S9(4) COMP VALUE 0.
          05 WS-SAVE-EIBAID  PIC X VALUE SPACE.
       01 WS-FILE-RECORD.
          05 WS-REC-KEY      PIC X(12).
          05 WS-REC-BAL      PIC S9(9)V99 COMP-3.
          05 WS-REC-STATUS   PIC X(08).
          05 WS-REC-FILLER   PIC X(40).
       01 WS-DISPLAY-FIELDS.
          05 WS-DISP-ACCT    PIC X(12).
          05 WS-DISP-BAL     PIC $$$,$$$,$$9.99.
          05 WS-DISP-STATUS  PIC X(08).
          05 WS-DISP-MSG     PIC X(60).
       01 WS-LINK-AREA.
          05 LK-FUNC         PIC X(08).
          05 LK-ACCT         PIC X(12).
          05 LK-AMOUNT       PIC S9(9)V99 COMP-3.
          05 LK-RC           PIC S9(4) COMP.
          05 LK-MSG          PIC X(40).
       01 WS-XCTL-AREA.
          05 XC-PROG         PIC X(08).
          05 XC-ACCT         PIC X(12).
          05 XC-MSG          PIC X(40).
       COPY DFHAID.
       COPY DFHBMSCA.
       01 HTA1I.
          05 FILLER          PIC X(12).
          05 ACCTIL          PIC S9(4) COMP.
          05 ACCTIF          PIC X.
          05 ACCTI           PIC X(12).
          05 TOACIL          PIC S9(4) COMP.
          05 TOACIF          PIC X.
          05 TOACI           PIC X(12).
          05 AMTIL           PIC S9(4) COMP.
          05 AMTIF           PIC X.
          05 AMTI            PIC X(12).
          05 CARDIL          PIC S9(4) COMP.
          05 CARDIF          PIC X.
          05 CARDI           PIC X(16).
          05 PINIL           PIC S9(4) COMP.
          05 PINIF           PIC X.
          05 PINI            PIC X(08).
          05 SRCHIL          PIC S9(4) COMP.
          05 SRCHIF          PIC X.
          05 SRCHI           PIC X(20).
          05 MSGIL           PIC S9(4) COMP.
          05 MSGIF           PIC X.
          05 MSGI            PIC X(60).
       01 HTA1O.
          05 FILLER          PIC X(12).
          05 ACCTOL          PIC S9(4) COMP.
          05 ACCTOF          PIC X.
          05 ACCTO           PIC X(12).
          05 TOACOL          PIC S9(4) COMP.
          05 TOACOF          PIC X.
          05 TOACO           PIC X(12).
          05 AMTOL           PIC S9(4) COMP.
          05 AMTOF           PIC X.
          05 AMTO            PIC X(12).
          05 CARDOL          PIC S9(4) COMP.
          05 CARDOF          PIC X.
          05 CARDO           PIC X(16).
          05 PINOL           PIC S9(4) COMP.
          05 PINOF           PIC X.
          05 PINO            PIC X(08).
          05 SRCHOL          PIC S9(4) COMP.
          05 SRCHOF          PIC X.
          05 SRCHO           PIC X(20).
          05 BALOL           PIC S9(4) COMP.
          05 BALOF           PIC X.
          05 BALO            PIC X(14).
          05 STSOL           PIC S9(4) COMP.
          05 STSOF           PIC X.
          05 STSO            PIC X(08).
          05 MSGOL           PIC S9(4) COMP.
          05 MSGOF           PIC X.
          05 MSGO            PIC X(60).
       LINKAGE SECTION.
       01 DFHCOMMAREA        PIC X(256).
       PROCEDURE DIVISION.
       0000-ENTRY.
           IF EIBCALEN > ZERO
               MOVE DFHCOMMAREA(1:128) TO WS-COMMAREA
           END-IF
           EVALUATE TRUE
               WHEN EIBCALEN = ZERO
                   MOVE 'Y' TO WS-FIRST-TIME
                   PERFORM 1000-SEND-MAP
               WHEN OTHER
                   PERFORM 2000-RECEIVE-MAP
           END-EVALUATE
           EXEC CICS RETURN TRANSID('HTAC')
               COMMAREA(WS-COMMAREA) LENGTH(128) END-EXEC
           .
       1000-SEND-MAP.
           MOVE LOW-VALUES TO HTA1O
           MOVE WS-ACCOUNT TO ACCTO
           MOVE WS-TO-ACCOUNT TO TOACO
           MOVE WS-MESSAGE TO MSGO
           MOVE WS-STATUS TO STSO
           IF WS-FIRST-TIME = 'Y'
               MOVE -1 TO ACCTIL
               MOVE 'Y' TO WS-EOF
               MOVE 'N' TO WS-FIRST-TIME
           END-IF
           EXEC CICS SEND MAP('HTA1') MAPSET('HTACMAP')
               FROM(HTA1O) ERASE RESP(WS-RESP) END-EXEC
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'SEND MAP FAILED' TO WS-MESSAGE
           END-IF
           .
       2000-RECEIVE-MAP.
           EXEC CICS RECEIVE MAP('HTA1') MAPSET('HTACMAP')
               INTO(HTA1I) RESP(WS-RESP) END-EXEC
           IF WS-RESP = DFHRESP(MAPFAIL)
               MOVE 'NO INPUT - ENTER DATA' TO WS-MESSAGE
               PERFORM 1000-SEND-MAP
               EXIT PARAGRAPH
           END-IF
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'RECEIVE MAP FAILED' TO WS-MESSAGE
               PERFORM 1000-SEND-MAP
               EXIT PARAGRAPH
           END-IF
           MOVE EIBAID TO WS-AID WS-SAVE-EIBAID
           EVALUATE WS-AID
               WHEN DFHENTER
                   PERFORM 3000-EDIT-INPUT
               WHEN DFHPF3
                   PERFORM 9000-EXIT-TRANSACTION
               WHEN DFHPF5
                   PERFORM 4000-EXECUTE-ACTION
               WHEN DFHPF6
                   PERFORM 5000-SCROLL-HANDLER
               WHEN DFHPF12
                   PERFORM 9000-EXIT-TRANSACTION
               WHEN DFHCLEAR
                   PERFORM 9100-CLEAR-SCREEN
               WHEN OTHER
                   MOVE 'USE ENTER PF3 PF5 PF6' TO WS-MESSAGE
                   PERFORM 1000-SEND-MAP
           END-EVALUATE
           .
       3000-EDIT-INPUT.
           MOVE 'Y' TO WS-EDIT-OK
           MOVE ACCTI TO WS-ACCOUNT
           MOVE TOACI TO WS-TO-ACCOUNT
           MOVE CARDI TO WS-CARD-NO
           MOVE PINI TO WS-PIN
           MOVE SRCHI TO WS-SEARCH-KEY
           IF ACCTIF = ' ' AND WS-ACCOUNT = SPACES
               MOVE 'ACCOUNT NUMBER REQUIRED' TO WS-MESSAGE
               MOVE 'N' TO WS-EDIT-OK
           END-IF
           IF WS-EDIT-OK = 'Y'
               PERFORM 3100-VALIDATE-ACCOUNT
           END-IF
           IF WS-EDIT-OK = 'Y'
               PERFORM 3200-VALIDATE-AMOUNT
           END-IF
           IF WS-EDIT-OK = 'Y'
               PERFORM 3300-VALIDATE-CARD
           END-IF
           IF WS-EDIT-OK = 'Y'
               PERFORM 3400-VALIDATE-PIN
           END-IF
           IF WS-EDIT-OK = 'N'
               PERFORM 1000-SEND-MAP
           ELSE
               PERFORM 4000-EXECUTE-ACTION
           END-IF
           .
       3100-VALIDATE-ACCOUNT.
           IF WS-ACCOUNT = SPACES
               MOVE 'ACCOUNT BLANK' TO WS-MESSAGE
               MOVE 'N' TO WS-EDIT-OK
           END-IF
           IF WS-ACCOUNT NOT NUMERIC
               MOVE 'ACCOUNT MUST BE NUMERIC' TO WS-MESSAGE
               MOVE 'N' TO WS-EDIT-OK
           END-IF
           .
       3200-VALIDATE-AMOUNT.
           IF AMTIF NOT = ' '
               IF AMTI = SPACES
                   MOVE 'AMOUNT BLANK' TO WS-MESSAGE
                   MOVE 'N' TO WS-EDIT-OK
               END-IF
           END-IF
           IF WS-EDIT-OK = 'Y' AND AMTIF NOT = ' '
               IF AMTI NOT NUMERIC
                   MOVE 'AMOUNT MUST BE NUMERIC' TO WS-MESSAGE
                   MOVE 'N' TO WS-EDIT-OK
               END-IF
           END-IF
           .
       3300-VALIDATE-CARD.
           IF CARDIF NOT = ' '
               IF CARDI = SPACES
                   MOVE 'CARD NUMBER BLANK' TO WS-MESSAGE
                   MOVE 'N' TO WS-EDIT-OK
               END-IF
           END-IF
           .
       3400-VALIDATE-PIN.
           IF PINIF NOT = ' '
               IF PINI = SPACES
                   MOVE 'PIN BLANK' TO WS-MESSAGE
                   MOVE 'N' TO WS-EDIT-OK
               END-IF
           END-IF
           .
       4000-EXECUTE-ACTION.
           MOVE WS-ACCOUNT TO WS-REC-KEY
           EXEC CICS READ FILE('HTACCT')
               INTO(WS-FILE-RECORD) RIDFLD(WS-REC-KEY)
               UPDATE RESP(WS-RESP) RESP2(WS-RESP2) END-EXEC
           EVALUATE WS-RESP
               WHEN DFHRESP(NORMAL)
                   PERFORM 4100-PROCESS-RECORD
               WHEN DFHRESP(NOTFND)
                   MOVE 'RECORD NOT FOUND' TO WS-MESSAGE
                   PERFORM 1000-SEND-MAP
               WHEN OTHER
                   MOVE 'READ FAILED' TO WS-MESSAGE
                   PERFORM 1000-SEND-MAP
           END-EVALUATE
           .
       4100-PROCESS-RECORD.
           MOVE WS-REC-BAL TO WS-BALANCE
           MOVE WS-REC-BAL TO WS-DISP-BAL
           MOVE WS-REC-STATUS TO WS-STATUS WS-DISP-STATUS
           MOVE WS-ACCOUNT TO WS-DISP-ACCT
           EXEC CICS REWRITE FILE('HTACCT')
               FROM(WS-FILE-RECORD) RESP(WS-RESP) END-EXEC
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'REWRITE FAILED' TO WS-MESSAGE
           ELSE
               MOVE 'INQUIRY OK' TO WS-MESSAGE
           END-IF
           PERFORM 4200-WRITE-AUDIT
           .
       4200-WRITE-AUDIT.
           MOVE WS-ACCOUNT TO WS-REC-KEY
           EXEC CICS WRITE FILE('HTAUDT')
               FROM(WS-FILE-RECORD) RIDFLD(WS-REC-KEY)
               RESP(WS-RESP) RESP2(WS-RESP2) END-EXEC
           IF WS-RESP = DFHRESP(DUPREC)
               MOVE 'AUDIT DUP - CONTINUING' TO WS-DISP-MSG
           END-IF
           PERFORM 4300-LINK-HELPER
           .
       4300-LINK-HELPER.
           MOVE 'INQUIRY' TO LK-FUNC
           MOVE WS-ACCOUNT TO LK-ACCT
           MOVE WS-AMOUNT TO LK-AMOUNT
           EXEC CICS LINK PROGRAM('HTAUDT')
               COMMAREA(WS-LINK-AREA) LENGTH(64)
               RESP(WS-RESP) END-EXEC
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'HELPER LINK FAILED' TO WS-DISP-MSG
           END-IF
           PERFORM 4400-XCTL-BRANCH
           .
       4400-XCTL-BRANCH.
           IF WS-STATUS = 'CLOSED'
               MOVE 'HTACINQ' TO XC-PROG
               MOVE WS-ACCOUNT TO XC-ACCT
               MOVE 'ACCOUNT CLOSED' TO XC-MSG
               EXEC CICS XCTL PROGRAM('HTMENU')
                   COMMAREA(WS-XCTL-AREA) LENGTH(60) END-EXEC
           END-IF
           PERFORM 4500-DELETE-OPTION
           .
       4500-DELETE-OPTION.
           IF WS-STATUS = 'PURGED'
               EXEC CICS DELETE FILE('HTACCT')
                   RIDFLD(WS-ACCOUNT) RESP(WS-RESP) END-EXEC
               IF WS-RESP NOT = DFHRESP(NORMAL)
                   MOVE 'DELETE FAILED' TO WS-MESSAGE
               END-IF
           END-IF
           PERFORM 1000-SEND-MAP
           .
       6000-BALANCE.
           MOVE 'BALANCE STARTED' TO WS-MESSAGE
           EXEC CICS READ FILE('HTACCT')
               INTO(WS-FILE-RECORD) RIDFLD(WS-ACCOUNT)
               RESP(WS-RESP) RESP2(WS-RESP2) END-EXEC
           IF WS-RESP = DFHRESP(NORMAL)
               PERFORM 6010-BALANCE-OK
           ELSE
               PERFORM 6020-BALANCE-ERROR
           END-IF
           .
       6010-BALANCE-OK.
           MOVE 'BALANCE COMPLETED OK' TO WS-MESSAGE
           ADD 1 TO WS-MATCH-COUNT
           .
       6020-BALANCE-ERROR.
           EVALUATE WS-RESP
               WHEN DFHRESP(NOTFND)
                   MOVE 'BALANCE RECORD NOT FOUND' TO WS-MESSAGE
               WHEN DFHRESP(DUPREC)
                   MOVE 'BALANCE DUPLICATE RECORD' TO WS-MESSAGE
               WHEN DFHRESP(LENGERR)
                   MOVE 'BALANCE LENGTH ERROR' TO WS-MESSAGE
               WHEN OTHER
                   MOVE 'BALANCE FILE ERROR' TO WS-MESSAGE
           END-EVALUATE
           .
       6100-HISTORY.
           MOVE 'HISTORY STARTED' TO WS-MESSAGE
           MOVE 'INQUIRY' TO LK-FUNC
           MOVE WS-ACCOUNT TO LK-ACCT
           EXEC CICS LINK PROGRAM('HTAUDT')
               COMMAREA(WS-LINK-AREA) LENGTH(64)
               RESP(WS-RESP) END-EXEC
           IF WS-RESP = DFHRESP(NORMAL)
               PERFORM 6110-HISTORY-OK
           ELSE
               PERFORM 6120-HISTORY-ERROR
           END-IF
           .
       6110-HISTORY-OK.
           MOVE 'HISTORY COMPLETED OK' TO WS-MESSAGE
           ADD 1 TO WS-MATCH-COUNT
           .
       6120-HISTORY-ERROR.
           EVALUATE WS-RESP
               WHEN DFHRESP(NOTFND)
                   MOVE 'HISTORY RECORD NOT FOUND' TO WS-MESSAGE
               WHEN DFHRESP(DUPREC)
                   MOVE 'HISTORY DUPLICATE RECORD' TO WS-MESSAGE
               WHEN DFHRESP(LENGERR)
                   MOVE 'HISTORY LENGTH ERROR' TO WS-MESSAGE
               WHEN OTHER
                   MOVE 'HISTORY FILE ERROR' TO WS-MESSAGE
           END-EVALUATE
           .
       6200-STATEMENT.
           MOVE 'STATEMENT STARTED' TO WS-MESSAGE
           MOVE 'HTACINQ' TO XC-PROG
           MOVE WS-ACCOUNT TO XC-ACCT
           EXEC CICS XCTL PROGRAM('HTMENU')
               COMMAREA(WS-XCTL-AREA) LENGTH(60) END-EXEC
           IF WS-RESP = DFHRESP(NORMAL)
               PERFORM 6210-STATEMENT-OK
           ELSE
               PERFORM 6220-STATEMENT-ERROR
           END-IF
           .
       6210-STATEMENT-OK.
           MOVE 'STATEMENT COMPLETED OK' TO WS-MESSAGE
           ADD 1 TO WS-MATCH-COUNT
           .
       6220-STATEMENT-ERROR.
           EVALUATE WS-RESP
               WHEN DFHRESP(NOTFND)
                   MOVE 'STATEMENT RECORD NOT FOUND' TO WS-MESSAGE
               WHEN DFHRESP(DUPREC)
                   MOVE 'STATEMENT DUPLICATE RECORD' TO WS-MESSAGE
               WHEN DFHRESP(LENGERR)
                   MOVE 'STATEMENT LENGTH ERROR' TO WS-MESSAGE
               WHEN OTHER
                   MOVE 'STATEMENT FILE ERROR' TO WS-MESSAGE
           END-EVALUATE
           .
       5000-SCROLL-HANDLER.
           IF EIBCALEN = ZERO
               MOVE 'NOTHING TO SCROLL' TO WS-MESSAGE
           ELSE
               ADD 1 TO WS-RETRY-COUNT
               MOVE 'SCROLL NOT SUPPORTED HERE' TO WS-MESSAGE
           END-IF
           PERFORM 1000-SEND-MAP
           .
       9000-EXIT-TRANSACTION.
           EXEC CICS SEND CONTROL ERASE RESP(WS-RESP) END-EXEC
           EXEC CICS RETURN END-EXEC
           .
       9100-CLEAR-SCREEN.
           MOVE SPACES TO WS-MESSAGE WS-STATUS
           MOVE SPACES TO WS-ACCOUNT WS-TO-ACCOUNT
           MOVE SPACES TO WS-CARD-NO WS-PIN WS-SEARCH-KEY
           MOVE ZERO TO WS-MATCH-COUNT WS-RETRY-COUNT
           PERFORM 1000-SEND-MAP
           .
