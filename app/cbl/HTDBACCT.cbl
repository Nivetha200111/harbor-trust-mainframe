       IDENTIFICATION DIVISION.
       PROGRAM-ID. HTDBACCT.
      ******************************************************************
      *> PROGRAM : HTDBACCT - ACCOUNT MASTER CURSOR READ (FICTIONAL)    *
      *> SYSTEM  : HARBOR TRUST MAINFRAME - DB2 ACCOUNT SERVICES       *
      *> PURPOSE : READ-ONLY SCAN OF FICTIONAL HT_ACCOUNT_MASTER TABLE *
      *>           USING CURSORS + HOST VARIABLES + SQLCODE HANDLING.  *
      *> FICTIONAL ONLY - NO REAL SCHEMA, NO REAL DATA, NO PII.        *
      *> MODE    : BATCH DB2 - READ ONLY, NO UPDATES IN THIS PROGRAM.  *
      *> COPYBOOKS (FICTIONAL): HTACCTCB, HTSTATCB VIA EXEC SQL INCLUDE*
      *> CURSORS : ACCT-CUR (PRIMARY), SUMM-CUR (TOTALS VERIFICATION).  *
      *> SQLCODE : 0 = OK, +100 = NOT FOUND, NEGATIVE = DB2 ERROR.     *
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-390.
       OBJECT-COMPUTER. IBM-390.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCT-REPORT ASSIGN TO ACCTRPT
               ORGANIZATION IS SEQUENTIAL.
           SELECT ACCT-ERRORS ASSIGN TO ACCTERR
               ORGANIZATION IS SEQUENTIAL.
       DATA DIVISION.
       FILE SECTION.
       FD  ACCT-REPORT
           RECORDING MODE IS F.
       01  ACCT-REPORT-REC PIC X(132).
       FD  ACCT-ERRORS
           RECORDING MODE IS F.
       01  ACCT-ERRORS-REC PIC X(132).
       WORKING-STORAGE SECTION.
      *---------------------------------------------------------------*
      *> SQL COMMUNICATION AREA - ALWAYS INCLUDED FOR DB2 PROGRAMS.    *
      *---------------------------------------------------------------*
           EXEC SQL INCLUDE SQLCA END-EXEC.
      *---------------------------------------------------------------*
      *> FICTIONAL COPYBOOK HOST-VARIABLE DEFINITIONS VIA SQL INCLUDE. *
      *> THESE COPYBOOKS ARE FICTIONAL AND CONTAIN ONLY LAYOUT SHELLS. *
      *---------------------------------------------------------------*
           EXEC SQL INCLUDE HTACCTCB END-EXEC.
           EXEC SQL INCLUDE HTSTATCB END-EXEC.
      *---------------------------------------------------------------*
      *> EXPLICIT HOST VARIABLE DECLARE SECTION (FICTIONAL LAYOUT).    *
      *---------------------------------------------------------------*
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01  HV-ACCT-ID PIC X(12).
       01  HV-ACCT-NAME PIC X(40).
       01  HV-ACCT-TYPE PIC X(10).
       01  HV-ACCT-BALANCE PIC S9(11)V99 COMP-3.
       01  HV-ACCT-STATUS PIC X(8).
       01  HV-ACCT-BRANCH PIC X(6).
       01  HV-ACCT-OPEN-DATE PIC X(10).
       01  HV-ACCT-LAST-ACT PIC X(10).
       01  HV-ACCT-RATE PIC S9V9999 COMP-3.
       01  HV-SUMM-STATUS PIC X(8).
       01  HV-SUMM-COUNT PIC S9(9) COMP.
       01  HV-SUMM-TOTAL PIC S9(13)V99 COMP-3.
       01  HV-FILTER-STATUS PIC X(8).
       01  HV-FILTER-BRANCH PIC X(6).
       01  HV-FILTER-MINBAL PIC S9(11)V99 COMP-3.
           EXEC SQL END DECLARE SECTION END-EXEC.
      *---------------------------------------------------------------*
      *> PROGRAM WORK FIELDS.                                          *
      *---------------------------------------------------------------*
       01  WS-SQLCODE PIC S9(9) COMP-5 VALUE ZERO.
       01  WS-SQLCODE-DISP PIC -ZZZZZZZZ9 VALUE ZERO.
       01  WS-EOF-FLAG PIC X VALUE "N".
           88 END-OF-CURSOR VALUE "Y".
           88 MORE-ROWS VALUE "N".
       01  WS-SUMM-EOF PIC X VALUE "N".
       01  WS-ROWS-READ PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-ROWS-WRITTEN PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-ROWS-SKIPPED PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-SUMM-ROWS PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-NEG-COUNT PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-NOTFOUND-COUNT PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-RETRY-COUNT PIC 9 VALUE ZERO.
       01  WS-MAX-RETRIES PIC 9 VALUE 3.
       01  WS-DISP-BAL PIC $$$,$$$,$$9.99 VALUE ZERO.
       01  WS-DISP-TOTAL PIC $$$,$$$,$$9.99 VALUE ZERO.
       01  WS-MESSAGE PIC X(100) VALUE SPACES.
       01  WS-REPORT-LINE PIC X(132) VALUE SPACES.
       01  WS-ERROR-LINE PIC X(132) VALUE SPACES.
       01  WS-RUN-DATE PIC X(10) VALUE "0000-00-00".
       01  WS-RUN-TIME PIC X(8) VALUE "00:00:00".
       01  WS-PROG-NAME PIC X(8) VALUE "HTDBACCT".
       01  WS-PAGE-NO PIC 9(5) VALUE 1.
       01  WS-LINE-COUNT PIC 9(3) VALUE 99.
       01  WS-MAX-LINES PIC 9(3) VALUE 55.
      *---------------------------------------------------------------*
      *> CURSOR DECLARATIONS (FICTIONAL TABLES/COLUMNS ONLY).          *
      *---------------------------------------------------------------*
           EXEC SQL DECLARE ACCT-CUR CURSOR FOR
             SELECT ACCT_ID, ACCT_NAME, ACCT_TYPE, ACCT_BALANCE,
                    ACCT_STATUS, ACCT_BRANCH, ACCT_OPEN_DATE,
                    ACCT_LAST_ACT, ACCT_RATE
               FROM HT_ACCOUNT_MASTER
              WHERE ACCT_STATUS = :HV-FILTER-STATUS
                AND ACCT_BRANCH = :HV-FILTER-BRANCH
                AND ACCT_BALANCE >= :HV-FILTER-MINBAL
              ORDER BY ACCT_ID
           END-EXEC.
           EXEC SQL DECLARE SUMM-CUR CURSOR FOR
             SELECT ACCT_STATUS, COUNT(*), SUM(ACCT_BALANCE)
               FROM HT_ACCOUNT_MASTER
              WHERE ACCT_BRANCH = :HV-FILTER-BRANCH
              GROUP BY ACCT_STATUS
              ORDER BY ACCT_STATUS
           END-EXEC.
       PROCEDURE DIVISION.
      *---------------------------------------------------------------*
      *> MAINLINE - CONTROLS OPEN / FETCH LOOP / CLOSE / SUMMARY.      *
      *---------------------------------------------------------------*
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 1100-SET-FILTERS
           PERFORM 1200-OPEN-PRIMARY
           IF END-OF-CURSOR
               CONTINUE
           ELSE
               PERFORM 2000-FETCH-LOOP
           END-IF
           PERFORM 3000-READ-SUMMARY
           PERFORM 8000-CLOSE-PRIMARY
           PERFORM 9000-WRITE-SUMMARY
           PERFORM 9500-TERMINATE
           GOBACK.
      *---------------------------------------------------------------*
      *> WHENEVER NOT FOUND APPLIES TO ALL SUBSEQUENT FETCHES.         *
      *> WE ALSO CODE EXPLICIT SQLCODE +100 CHECKS FOR CLARITY.        *
      *---------------------------------------------------------------*
       1000-INITIALIZE.
           EXEC SQL WHENEVER NOT FOUND CONTINUE END-EXEC
           MOVE "N" TO WS-EOF-FLAG
           MOVE "N" TO WS-SUMM-EOF
           MOVE ZERO TO WS-ROWS-READ
           MOVE ZERO TO WS-ROWS-WRITTEN
           MOVE ZERO TO WS-ROWS-SKIPPED
           MOVE ZERO TO WS-SUMM-ROWS
           MOVE ZERO TO WS-NEG-COUNT
           MOVE ZERO TO WS-NOTFOUND-COUNT
           MOVE ZERO TO WS-RETRY-COUNT
           MOVE 1 TO WS-PAGE-NO
           MOVE 99 TO WS-LINE-COUNT
           OPEN OUTPUT ACCT-REPORT
           OPEN OUTPUT ACCT-ERRORS
           PERFORM 1050-WRITE-HEADING
           EXIT.
       1050-WRITE-HEADING.
           MOVE SPACES TO WS-REPORT-LINE
           STRING "HARBOR TRUST - ACCOUNT MASTER LIST - "
               WS-PROG-NAME
               DELIMITED BY SIZE INTO WS-REPORT-LINE
           END-STRING
           WRITE ACCT-REPORT-REC FROM WS-REPORT-LINE
           MOVE SPACES TO WS-REPORT-LINE
           STRING "ID          NAME  TYPE  BALANCE  STATUS  BRANCH"
               DELIMITED BY SIZE INTO WS-REPORT-LINE
           END-STRING
           WRITE ACCT-REPORT-REC FROM WS-REPORT-LINE
           MOVE 2 TO WS-LINE-COUNT
           EXIT.
       1100-SET-FILTERS.
           MOVE "ACTIVE" TO HV-FILTER-STATUS
           MOVE "BR001 " TO HV-FILTER-BRANCH
           MOVE ZERO TO HV-FILTER-MINBAL
           MOVE HV-FILTER-STATUS TO HV-ACCT-STATUS
           EXIT.
       1200-OPEN-PRIMARY.
           EXEC SQL OPEN ACCT-CUR END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           EVALUATE SQLCODE
             WHEN 0
               CONTINUE
             WHEN OTHER
               PERFORM 9100-SQL-FAILURE
               MOVE "Y" TO WS-EOF-FLAG
           END-EVALUATE
           EXIT.
       2000-FETCH-LOOP.
           PERFORM UNTIL END-OF-CURSOR
               PERFORM 2100-FETCH-ROW
               IF NOT END-OF-CURSOR
                   PERFORM 2200-HANDLE-ROW
               END-IF
           END-PERFORM
           EXIT.
       2100-FETCH-ROW.
           EXEC SQL FETCH ACCT-CUR
             INTO :HV-ACCT-ID, :HV-ACCT-NAME, :HV-ACCT-TYPE,
                  :HV-ACCT-BALANCE, :HV-ACCT-STATUS, :HV-ACCT-BRANCH,
                  :HV-ACCT-OPEN-DATE, :HV-ACCT-LAST-ACT, :HV-ACCT-RATE
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           EVALUATE SQLCODE
             WHEN 0
               ADD 1 TO WS-ROWS-READ
             WHEN 100
               MOVE "Y" TO WS-EOF-FLAG
               ADD 1 TO WS-NOTFOUND-COUNT
             WHEN OTHER
               PERFORM 9200-NEGATIVE-SQLCODE
           END-EVALUATE
           EXIT.
       2200-HANDLE-ROW.
           PERFORM 2300-VALIDATE-ROW
           PERFORM 2400-CLASSIFY-SQLCODE
           PERFORM 2500-WRITE-ROW
           EXIT.
       2300-VALIDATE-ROW.
           IF HV-ACCT-ID = SPACES
               ADD 1 TO WS-ROWS-SKIPPED
               MOVE "BLANK ACCT-ID SKIPPED" TO WS-MESSAGE
               PERFORM 9300-LOG-ROW-ERROR
           END-IF
           IF HV-ACCT-BALANCE < ZERO
               ADD 1 TO WS-ROWS-SKIPPED
               MOVE "NEGATIVE BALANCE FLAGGED" TO WS-MESSAGE
               PERFORM 9300-LOG-ROW-ERROR
           END-IF
           IF HV-ACCT-STATUS NOT = "ACTIVE"
               AND HV-ACCT-STATUS NOT = "DORMANT"
               AND HV-ACCT-STATUS NOT = "CLOSED "
               ADD 1 TO WS-ROWS-SKIPPED
               MOVE "BAD STATUS SKIPPED" TO WS-MESSAGE
               PERFORM 9300-LOG-ROW-ERROR
           END-IF
           IF HV-ACCT-BRANCH = SPACES
               MOVE "BR001 " TO HV-ACCT-BRANCH
           END-IF
           EXIT.
       2400-CLASSIFY-SQLCODE.
           MOVE WS-SQLCODE TO WS-SQLCODE-DISP
           EVALUATE WS-SQLCODE
             WHEN 0
               CONTINUE
             WHEN 100
               MOVE "Y" TO WS-EOF-FLAG
             WHEN OTHER
               PERFORM 9200-NEGATIVE-SQLCODE
           END-EVALUATE
           EXIT.
       2500-WRITE-ROW.
           IF WS-LINE-COUNT >= WS-MAX-LINES
               PERFORM 2600-PAGE-BREAK
           END-IF
           MOVE SPACES TO WS-REPORT-LINE
           MOVE HV-ACCT-BALANCE TO WS-DISP-BAL
           STRING HV-ACCT-ID " " HV-ACCT-NAME " " HV-ACCT-TYPE " "
               WS-DISP-BAL " " HV-ACCT-STATUS " " HV-ACCT-BRANCH
               DELIMITED BY SIZE INTO WS-REPORT-LINE
           END-STRING
           WRITE ACCT-REPORT-REC FROM WS-REPORT-LINE
           ADD 1 TO WS-ROWS-WRITTEN
           ADD 1 TO WS-LINE-COUNT
           EXIT.
       2600-PAGE-BREAK.
           ADD 1 TO WS-PAGE-NO
           MOVE ZERO TO WS-LINE-COUNT
           MOVE SPACES TO WS-REPORT-LINE
           STRING "PAGE " WS-PAGE-NO
               DELIMITED BY SIZE INTO WS-REPORT-LINE
           END-STRING
           WRITE ACCT-REPORT-REC FROM WS-REPORT-LINE
           PERFORM 1050-WRITE-HEADING
           EXIT.
       3000-READ-SUMMARY.
           EXEC SQL OPEN SUMM-CUR END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           EVALUATE SQLCODE
             WHEN 0
               PERFORM 3100-SUMM-LOOP
             WHEN 100
               MOVE "EMPTY SUMMARY CURSOR" TO WS-MESSAGE
             WHEN OTHER
               PERFORM 9100-SQL-FAILURE
           END-EVALUATE
           EXEC SQL CLOSE SUMM-CUR END-EXEC
           EXIT.
       3100-SUMM-LOOP.
           MOVE "N" TO WS-SUMM-EOF
           PERFORM UNTIL WS-SUMM-EOF = "Y"
               EXEC SQL FETCH SUMM-CUR
                 INTO :HV-SUMM-STATUS, :HV-SUMM-COUNT, :HV-SUMM-TOTAL
               END-EXEC
               MOVE SQLCODE TO WS-SQLCODE
               EVALUATE SQLCODE
                 WHEN 0
                   ADD 1 TO WS-SUMM-ROWS
                   PERFORM 3200-WRITE-SUMM-ROW
                 WHEN 100
                   MOVE "Y" TO WS-SUMM-EOF
                 WHEN OTHER
                   PERFORM 9200-NEGATIVE-SQLCODE
                   MOVE "Y" TO WS-SUMM-EOF
               END-EVALUATE
           END-PERFORM
           EXIT.
       3200-WRITE-SUMM-ROW.
           MOVE SPACES TO WS-REPORT-LINE
           MOVE HV-SUMM-TOTAL TO WS-DISP-TOTAL
           STRING "SUMMARY " HV-SUMM-STATUS " COUNT "
               HV-SUMM-COUNT " TOTAL " WS-DISP-TOTAL
               DELIMITED BY SIZE INTO WS-REPORT-LINE
           END-STRING
           WRITE ACCT-REPORT-REC FROM WS-REPORT-LINE
           EXIT.
       8000-CLOSE-PRIMARY.
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
           MOVE SPACES TO WS-REPORT-LINE
           STRING "READ=" WS-ROWS-READ " WRITTEN=" WS-ROWS-WRITTEN
               " SKIPPED=" WS-ROWS-SKIPPED
               DELIMITED BY SIZE INTO WS-REPORT-LINE
           END-STRING
           WRITE ACCT-REPORT-REC FROM WS-REPORT-LINE
           MOVE SPACES TO WS-REPORT-LINE
           STRING "NOTFOUND=" WS-NOTFOUND-COUNT " NEG=" WS-NEG-COUNT
               DELIMITED BY SIZE INTO WS-REPORT-LINE
           END-STRING
           WRITE ACCT-REPORT-REC FROM WS-REPORT-LINE
           EXIT.
       9100-SQL-FAILURE.
           MOVE SQLCODE TO WS-SQLCODE-DISP
           MOVE SPACES TO WS-ERROR-LINE
           STRING "SQL FAILURE CODE=" WS-SQLCODE-DISP
               DELIMITED BY SIZE INTO WS-ERROR-LINE
           END-STRING
           WRITE ACCT-ERRORS-REC FROM WS-ERROR-LINE
           ADD 1 TO WS-NEG-COUNT
           EXIT.
       9200-NEGATIVE-SQLCODE.
           MOVE SQLCODE TO WS-SQLCODE-DISP
           MOVE SPACES TO WS-ERROR-LINE
           STRING "NEG SQLCODE=" WS-SQLCODE-DISP " ID=" HV-ACCT-ID
               DELIMITED BY SIZE INTO WS-ERROR-LINE
           END-STRING
           WRITE ACCT-ERRORS-REC FROM WS-ERROR-LINE
           ADD 1 TO WS-NEG-COUNT
           IF WS-NEG-COUNT > 10
               MOVE "Y" TO WS-EOF-FLAG
           END-IF
           EXIT.
       9300-LOG-ROW-ERROR.
           MOVE SPACES TO WS-ERROR-LINE
           STRING "ROW ERROR " WS-MESSAGE " ID=" HV-ACCT-ID
               DELIMITED BY SIZE INTO WS-ERROR-LINE
           END-STRING
           WRITE ACCT-ERRORS-REC FROM WS-ERROR-LINE
           EXIT.
       9500-TERMINATE.
           CLOSE ACCT-REPORT
           CLOSE ACCT-ERRORS
           EXIT.
