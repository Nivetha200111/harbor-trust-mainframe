       IDENTIFICATION DIVISION.
       PROGRAM-ID. HTDBSTMT.
      ******************************************************************
      * PROGRAM : HTDBSTMT - MULTI-CURSOR JOIN READ (FICTIONAL)        *
      * SYSTEM  : HARBOR TRUST MAINFRAME - DB2 STATEMENT SERVICES     *
      * PURPOSE : BUILD FICTIONAL MONTHLY STATEMENTS USING THREE      *
      *           READ-ONLY CURSORS JOINING FICTIONAL ACCOUNT,         *
      *           TRANSACTION AND BRANCH TABLES. NO UPDATES.          *
      * FICTIONAL ONLY - NO REAL SCHEMA, NO REAL DATA, NO PII.        *
      * MODE    : BATCH DB2 - READ ONLY, MULTI-CURSOR JOIN READ.      *
      * COPYBOOKS (FICTIONAL): HTACCTCB, HTTRANCB, HTBRCHCB VIA       *
      *           EXEC SQL INCLUDE.                                   *
      * CURSORS : ACCT-CUR (ACCOUNTS), TRAN-CUR (TRANSACTIONS JOIN),  *
      *           BRCH-CUR (BRANCH MASTER).                           *
      * SQLCODE : 0 = OK, +100 = NOT FOUND, NEGATIVE = DB2 ERROR.     *
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-390.
       OBJECT-COMPUTER. IBM-390.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT STMT-FILE ASSIGN TO STMTFILE
               ORGANIZATION IS SEQUENTIAL.
           SELECT STMT-ERRORS ASSIGN TO STMTERR
               ORGANIZATION IS SEQUENTIAL.
       DATA DIVISION.
       FILE SECTION.
       FD  STMT-FILE
           RECORDING MODE IS F.
       01  STMT-FILE-REC PIC X(132).
       FD  STMT-ERRORS
           RECORDING MODE IS F.
       01  STMT-ERRORS-REC PIC X(132).
       WORKING-STORAGE SECTION.
      *---------------------------------------------------------------*
      * SQL COMMUNICATION AREA.                                       *
      *---------------------------------------------------------------*
           EXEC SQL INCLUDE SQLCA END-EXEC.
      *---------------------------------------------------------------*
      * FICTIONAL COPYBOOK HOST-VARIABLE DEFINITIONS VIA SQL INCLUDE. *
      *---------------------------------------------------------------*
           EXEC SQL INCLUDE HTACCTCB END-EXEC.
           EXEC SQL INCLUDE HTTRANCB END-EXEC.
           EXEC SQL INCLUDE HTBRCHCB END-EXEC.
      *---------------------------------------------------------------*
      * EXPLICIT HOST VARIABLE DECLARE SECTION (FICTIONAL LAYOUT).    *
      *---------------------------------------------------------------*
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01  HV-ACCT-ID PIC X(12).
       01  HV-ACCT-NAME PIC X(40).
       01  HV-ACCT-STATUS PIC X(8).
       01  HV-ACCT-BRANCH PIC X(6).
       01  HV-ACCT-BALANCE PIC S9(11)V99 COMP-3.
       01  HV-TRAN-ID PIC X(16).
       01  HV-TRAN-DATE PIC X(10).
       01  HV-TRAN-AMT PIC S9(11)V99 COMP-3.
       01  HV-TRAN-TYPE PIC X(10).
       01  HV-TRAN-DESC PIC X(30).
       01  HV-BRCH-ID PIC X(6).
       01  HV-BRCH-NAME PIC X(30).
       01  HV-BRCH-CITY PIC X(20).
       01  HV-FILTER-BRANCH PIC X(6).
       01  HV-FILTER-DATE PIC X(10).
       01  HV-JOIN-ACCT PIC X(12).
           EXEC SQL END DECLARE SECTION END-EXEC.
      *---------------------------------------------------------------*
      * PROGRAM WORK FIELDS.                                          *
      *---------------------------------------------------------------*
       01  WS-SQLCODE PIC S9(9) COMP-5 VALUE ZERO.
       01  WS-SQLCODE-DISP PIC -ZZZZZZZZ9 VALUE ZERO.
       01  WS-ACCT-EOF PIC X VALUE "N".
       01  WS-TRAN-EOF PIC X VALUE "N".
       01  WS-BRCH-EOF PIC X VALUE "N".
       01  WS-ACCTS-READ PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-TRANS-READ PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-BRANCHES-READ PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-STMTS-WRITTEN PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-TRAN-LINES PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-NOTFOUND-COUNT PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-NEG-COUNT PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-SKIPPED PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-DISP-BAL PIC $$$,$$$,$$9.99 VALUE ZERO.
       01  WS-DISP-AMT PIC $$$,$$$,$$9.99 VALUE ZERO.
       01  WS-MESSAGE PIC X(100) VALUE SPACES.
       01  WS-STMT-LINE PIC X(132) VALUE SPACES.
       01  WS-ERROR-LINE PIC X(132) VALUE SPACES.
       01  WS-PROG-NAME PIC X(8) VALUE "HTDBSTMT".
       01  WS-PAGE-NO PIC 9(5) VALUE 1.
       01  WS-LINE-COUNT PIC 9(3) VALUE 99.
       01  WS-MAX-LINES PIC 9(3) VALUE 50.
      *---------------------------------------------------------------*
      * THREE READ-ONLY CURSORS - ONE JOINS TWO FICTIONAL TABLES.     *
      *---------------------------------------------------------------*
           EXEC SQL DECLARE ACCT-CUR CURSOR FOR
             SELECT A.ACCT_ID, A.ACCT_NAME, A.ACCT_STATUS,
                    A.ACCT_BRANCH, A.ACCT_BALANCE
               FROM HT_ACCOUNT_MASTER A
              WHERE A.ACCT_BRANCH = :HV-FILTER-BRANCH
                AND A.ACCT_STATUS IN ('ACTIVE', 'DORMANT')
              ORDER BY A.ACCT_ID
           END-EXEC.
           EXEC SQL DECLARE TRAN-CUR CURSOR FOR
             SELECT T.TRAN_ID, T.TRAN_DATE, T.TRAN_AMT,
                    T.TRAN_TYPE, T.TRAN_DESC
               FROM HT_TRANSACTION_HIST T
               INNER JOIN HT_ACCOUNT_MASTER A
                  ON T.TRAN_ACCT = A.ACCT_ID
              WHERE T.TRAN_ACCT = :HV-JOIN-ACCT
                AND T.TRAN_DATE >= :HV-FILTER-DATE
              ORDER BY T.TRAN_DATE, T.TRAN_ID
           END-EXEC.
           EXEC SQL DECLARE BRCH-CUR CURSOR FOR
             SELECT BRCH_ID, BRCH_NAME, BRCH_CITY
               FROM HT_BRANCH_MASTER
              ORDER BY BRCH_ID
           END-EXEC.
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 1100-SET-FILTERS
           PERFORM 1200-LOAD-BRANCHES
           PERFORM 1300-OPEN-ACCOUNTS
           IF WS-ACCT-EOF = "Y"
               CONTINUE
           ELSE
               PERFORM 2000-ACCT-LOOP
           END-IF
           PERFORM 8000-CLOSE-ACCOUNTS
           PERFORM 9000-WRITE-SUMMARY
           PERFORM 9500-TERMINATE
           GOBACK.
       1000-INITIALIZE.
           EXEC SQL WHENEVER NOT FOUND CONTINUE END-EXEC
           MOVE "N" TO WS-ACCT-EOF
           MOVE "N" TO WS-TRAN-EOF
           MOVE "N" TO WS-BRCH-EOF
           MOVE ZERO TO WS-ACCTS-READ
           MOVE ZERO TO WS-TRANS-READ
           MOVE ZERO TO WS-BRANCHES-READ
           MOVE ZERO TO WS-STMTS-WRITTEN
           MOVE ZERO TO WS-TRAN-LINES
           MOVE ZERO TO WS-NOTFOUND-COUNT
           MOVE ZERO TO WS-NEG-COUNT
           MOVE ZERO TO WS-SKIPPED
           MOVE 1 TO WS-PAGE-NO
           MOVE 99 TO WS-LINE-COUNT
           OPEN OUTPUT STMT-FILE
           OPEN OUTPUT STMT-ERRORS
           PERFORM 1050-WRITE-HEADING
           EXIT.
       1050-WRITE-HEADING.
           MOVE SPACES TO WS-STMT-LINE
           STRING "HARBOR TRUST - MONTHLY STATEMENTS - "
               WS-PROG-NAME
               DELIMITED BY SIZE INTO WS-STMT-LINE
           END-STRING
           WRITE STMT-FILE-REC FROM WS-STMT-LINE
           MOVE SPACES TO WS-STMT-LINE
           STRING "ACCT  NAME  STATUS  BALANCE"
               DELIMITED BY SIZE INTO WS-STMT-LINE
           END-STRING
           WRITE STMT-FILE-REC FROM WS-STMT-LINE
           MOVE 2 TO WS-LINE-COUNT
           EXIT.
       1100-SET-FILTERS.
           MOVE "BR001 " TO HV-FILTER-BRANCH
           MOVE "0000-00-01" TO HV-FILTER-DATE
           MOVE SPACES TO HV-JOIN-ACCT
           EXIT.
       1200-LOAD-BRANCHES.
           EXEC SQL OPEN BRCH-CUR END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           EVALUATE SQLCODE
             WHEN 0
               PERFORM 1210-BRANCH-LOOP
             WHEN 100
               ADD 1 TO WS-NOTFOUND-COUNT
               MOVE "NO BRANCH ROWS" TO WS-MESSAGE
             WHEN OTHER
               PERFORM 9100-SQL-FAILURE
           END-EVALUATE
           EXEC SQL CLOSE BRCH-CUR END-EXEC
           EXIT.
       1210-BRANCH-LOOP.
           MOVE "N" TO WS-BRCH-EOF
           PERFORM UNTIL WS-BRCH-EOF = "Y"
               EXEC SQL FETCH BRCH-CUR
                 INTO :HV-BRCH-ID, :HV-BRCH-NAME, :HV-BRCH-CITY
               END-EXEC
               MOVE SQLCODE TO WS-SQLCODE
               EVALUATE SQLCODE
                 WHEN 0
                   ADD 1 TO WS-BRANCHES-READ
                   PERFORM 1220-WRITE-BRANCH
                 WHEN 100
                   MOVE "Y" TO WS-BRCH-EOF
                   ADD 1 TO WS-NOTFOUND-COUNT
                 WHEN OTHER
                   PERFORM 9200-NEGATIVE-SQLCODE
                   MOVE "Y" TO WS-BRCH-EOF
               END-EVALUATE
           END-PERFORM
           EXIT.
       1220-WRITE-BRANCH.
           MOVE SPACES TO WS-STMT-LINE
           STRING "BRANCH " HV-BRCH-ID " " HV-BRCH-NAME
               " " HV-BRCH-CITY
               DELIMITED BY SIZE INTO WS-STMT-LINE
           END-STRING
           WRITE STMT-FILE-REC FROM WS-STMT-LINE
           EXIT.
       1300-OPEN-ACCOUNTS.
           EXEC SQL OPEN ACCT-CUR END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           EVALUATE SQLCODE
             WHEN 0
               CONTINUE
             WHEN OTHER
               PERFORM 9100-SQL-FAILURE
               MOVE "Y" TO WS-ACCT-EOF
           END-EVALUATE
           EXIT.
       2000-ACCT-LOOP.
           PERFORM UNTIL WS-ACCT-EOF = "Y"
               PERFORM 2100-FETCH-ACCOUNT
               IF WS-ACCT-EOF NOT = "Y"
                   PERFORM 2200-BUILD-STATEMENT
               END-IF
           END-PERFORM
           EXIT.
       2100-FETCH-ACCOUNT.
           EXEC SQL FETCH ACCT-CUR
             INTO :HV-ACCT-ID, :HV-ACCT-NAME, :HV-ACCT-STATUS,
                  :HV-ACCT-BRANCH, :HV-ACCT-BALANCE
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           EVALUATE SQLCODE
             WHEN 0
               ADD 1 TO WS-ACCTS-READ
             WHEN 100
               MOVE "Y" TO WS-ACCT-EOF
               ADD 1 TO WS-NOTFOUND-COUNT
             WHEN OTHER
               PERFORM 9200-NEGATIVE-SQLCODE
           END-EVALUATE
           EXIT.
       2200-BUILD-STATEMENT.
           PERFORM 2300-VALIDATE-ACCOUNT
           IF WS-MESSAGE = SPACES
               PERFORM 2400-WRITE-ACCT-HEADER
               PERFORM 3000-READ-TRANSACTIONS
               PERFORM 4000-WRITE-ACCT-FOOTER
           ELSE
               ADD 1 TO WS-SKIPPED
               PERFORM 9300-LOG-ROW-ERROR
               MOVE SPACES TO WS-MESSAGE
           END-IF
           EXIT.
       2300-VALIDATE-ACCOUNT.
           MOVE SPACES TO WS-MESSAGE
           IF HV-ACCT-ID = SPACES
               MOVE "BLANK ACCT-ID" TO WS-MESSAGE
           END-IF
           IF HV-ACCT-STATUS NOT = "ACTIVE"
               AND HV-ACCT-STATUS NOT = "DORMANT"
               MOVE "BAD ACCT STATUS" TO WS-MESSAGE
           END-IF
           EXIT.
       2400-WRITE-ACCT-HEADER.
           IF WS-LINE-COUNT >= WS-MAX-LINES
               PERFORM 2500-PAGE-BREAK
           END-IF
           MOVE SPACES TO WS-STMT-LINE
           MOVE HV-ACCT-BALANCE TO WS-DISP-BAL
           STRING "ACCT " HV-ACCT-ID " " HV-ACCT-NAME
               " " HV-ACCT-STATUS " " WS-DISP-BAL
               DELIMITED BY SIZE INTO WS-STMT-LINE
           END-STRING
           WRITE STMT-FILE-REC FROM WS-STMT-LINE
           ADD 1 TO WS-LINE-COUNT
           MOVE SPACES TO WS-STMT-LINE
           STRING "  DATE  TRAN-ID  TYPE  AMOUNT  DESCRIPTION"
               DELIMITED BY SIZE INTO WS-STMT-LINE
           END-STRING
           WRITE STMT-FILE-REC FROM WS-STMT-LINE
           ADD 1 TO WS-LINE-COUNT
           EXIT.
       2500-PAGE-BREAK.
           ADD 1 TO WS-PAGE-NO
           MOVE ZERO TO WS-LINE-COUNT
           PERFORM 1050-WRITE-HEADING
           EXIT.
       3000-READ-TRANSACTIONS.
           MOVE HV-ACCT-ID TO HV-JOIN-ACCT
           MOVE ZERO TO WS-TRAN-LINES
           EXEC SQL OPEN TRAN-CUR END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           EVALUATE SQLCODE
             WHEN 0
               PERFORM 3100-TRAN-LOOP
             WHEN 100
               ADD 1 TO WS-NOTFOUND-COUNT
               PERFORM 3300-NO-ACTIVITY
             WHEN OTHER
               PERFORM 9100-SQL-FAILURE
           END-EVALUATE
           EXEC SQL CLOSE TRAN-CUR END-EXEC
           EXIT.
       3100-TRAN-LOOP.
           MOVE "N" TO WS-TRAN-EOF
           PERFORM UNTIL WS-TRAN-EOF = "Y"
               EXEC SQL FETCH TRAN-CUR
                 INTO :HV-TRAN-ID, :HV-TRAN-DATE, :HV-TRAN-AMT,
                      :HV-TRAN-TYPE, :HV-TRAN-DESC
               END-EXEC
               MOVE SQLCODE TO WS-SQLCODE
               EVALUATE SQLCODE
                 WHEN 0
                   ADD 1 TO WS-TRANS-READ
                   ADD 1 TO WS-TRAN-LINES
                   PERFORM 3200-WRITE-TRAN-LINE
                 WHEN 100
                   MOVE "Y" TO WS-TRAN-EOF
                   ADD 1 TO WS-NOTFOUND-COUNT
                 WHEN OTHER
                   PERFORM 9200-NEGATIVE-SQLCODE
                   MOVE "Y" TO WS-TRAN-EOF
               END-EVALUATE
           END-PERFORM
           EXIT.
       3200-WRITE-TRAN-LINE.
           MOVE SPACES TO WS-STMT-LINE
           MOVE HV-TRAN-AMT TO WS-DISP-AMT
           STRING "  " HV-TRAN-DATE " " HV-TRAN-ID
               " " HV-TRAN-TYPE " " WS-DISP-AMT
               " " HV-TRAN-DESC
               DELIMITED BY SIZE INTO WS-STMT-LINE
           END-STRING
           WRITE STMT-FILE-REC FROM WS-STMT-LINE
           ADD 1 TO WS-LINE-COUNT
           EXIT.
       3300-NO-ACTIVITY.
           MOVE SPACES TO WS-STMT-LINE
           STRING "  NO ACTIVITY FOR " HV-JOIN-ACCT
               DELIMITED BY SIZE INTO WS-STMT-LINE
           END-STRING
           WRITE STMT-FILE-REC FROM WS-STMT-LINE
           ADD 1 TO WS-LINE-COUNT
           EXIT.
       4000-WRITE-ACCT-FOOTER.
           MOVE SPACES TO WS-STMT-LINE
           STRING "  LINES=" WS-TRAN-LINES " BAL=" WS-DISP-BAL
               DELIMITED BY SIZE INTO WS-STMT-LINE
           END-STRING
           WRITE STMT-FILE-REC FROM WS-STMT-LINE
           ADD 1 TO WS-LINE-COUNT
           ADD 1 TO WS-STMTS-WRITTEN
           EXIT.
       8000-CLOSE-ACCOUNTS.
           EXEC SQL CLOSE ACCT-CUR END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           EVALUATE SQLCODE
             WHEN 0
               CONTINUE
             WHEN OTHER
               PERFORM 9100-SQL-FAILURE
           END-EVALUATE
           EXIT.
       9000-WRITE-SUMMARY.
           MOVE SPACES TO WS-STMT-LINE
           STRING "ACCTS=" WS-ACCTS-READ " TRANS=" WS-TRANS-READ
               " STMTS=" WS-STMTS-WRITTEN
               DELIMITED BY SIZE INTO WS-STMT-LINE
           END-STRING
           WRITE STMT-FILE-REC FROM WS-STMT-LINE
           MOVE SPACES TO WS-STMT-LINE
           STRING "SKIPPED=" WS-SKIPPED " NEG=" WS-NEG-COUNT
               DELIMITED BY SIZE INTO WS-STMT-LINE
           END-STRING
           WRITE STMT-FILE-REC FROM WS-STMT-LINE
           EXIT.
       9100-SQL-FAILURE.
           MOVE SQLCODE TO WS-SQLCODE-DISP
           MOVE SPACES TO WS-ERROR-LINE
           STRING "SQL FAILURE CODE=" WS-SQLCODE-DISP
               DELIMITED BY SIZE INTO WS-ERROR-LINE
           END-STRING
           WRITE STMT-ERRORS-REC FROM WS-ERROR-LINE
           ADD 1 TO WS-NEG-COUNT
           EXIT.
       9200-NEGATIVE-SQLCODE.
           MOVE SQLCODE TO WS-SQLCODE-DISP
           MOVE SPACES TO WS-ERROR-LINE
           STRING "NEG SQLCODE=" WS-SQLCODE-DISP " ACCT=" HV-ACCT-ID
               DELIMITED BY SIZE INTO WS-ERROR-LINE
           END-STRING
           WRITE STMT-ERRORS-REC FROM WS-ERROR-LINE
           ADD 1 TO WS-NEG-COUNT
           EXIT.
       9300-LOG-ROW-ERROR.
           MOVE SPACES TO WS-ERROR-LINE
           STRING "ROW ERROR " WS-MESSAGE " ACCT=" HV-ACCT-ID
               DELIMITED BY SIZE INTO WS-ERROR-LINE
           END-STRING
           WRITE STMT-ERRORS-REC FROM WS-ERROR-LINE
           EXIT.
       9500-TERMINATE.
           CLOSE STMT-FILE
           CLOSE STMT-ERRORS
           EXIT.
