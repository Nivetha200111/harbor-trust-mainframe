       IDENTIFICATION DIVISION.
       PROGRAM-ID. HTDBTRAN.
      ******************************************************************
      * PROGRAM : HTDBTRAN - TRANSFER POSTING WITH CURSOR FOR UPDATE  *
      * SYSTEM  : HARBOR TRUST MAINFRAME - DB2 TRANSFER SERVICES      *
      * PURPOSE : SCAN FICTIONAL HT_TRANSFER_QUEUE WITH CURSOR        *
      *           FOR UPDATE, POST EACH ROW, COMMIT ON SUCCESS AND     *
      *           ROLLBACK ON FAILURE. FICTIONAL ONLY - NO REAL MONEY *
      *           MOVES, NO REAL ACCOUNTS, NO PII.                    *
      * MODE    : BATCH DB2 UPDATE - COMMIT/ROLLBACK LOGIC REQUIRED.  *
      * COPYBOOKS (FICTIONAL): HTTRANCB, HTBALCB VIA EXEC SQL INCLUDE *
      * CURSOR  : TRAN-CUR FOR UPDATE OF TRAN_STATUS, TRAN_POST_DATE. *
      * SQLCODE : 0 = OK, +100 = NOT FOUND, NEGATIVE = DB2 ERROR.     *
      ******************************************************************
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. IBM-390.
       OBJECT-COMPUTER. IBM-390.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRAN-JOURNAL ASSIGN TO TRANJRNL
               ORGANIZATION IS SEQUENTIAL.
           SELECT TRAN-ERRORS ASSIGN TO TRANERR
               ORGANIZATION IS SEQUENTIAL.
       DATA DIVISION.
       FILE SECTION.
       FD  TRAN-JOURNAL
           RECORDING MODE IS F.
       01  TRAN-JOURNAL-REC PIC X(132).
       FD  TRAN-ERRORS
           RECORDING MODE IS F.
       01  TRAN-ERRORS-REC PIC X(132).
       WORKING-STORAGE SECTION.
      *---------------------------------------------------------------*
      * SQL COMMUNICATION AREA.                                       *
      *---------------------------------------------------------------*
           EXEC SQL INCLUDE SQLCA END-EXEC.
      *---------------------------------------------------------------*
      * FICTIONAL COPYBOOK HOST-VARIABLE DEFINITIONS VIA SQL INCLUDE. *
      *---------------------------------------------------------------*
           EXEC SQL INCLUDE HTTRANCB END-EXEC.
           EXEC SQL INCLUDE HTBALCB END-EXEC.
      *---------------------------------------------------------------*
      * EXPLICIT HOST VARIABLE DECLARE SECTION (FICTIONAL LAYOUT).    *
      *---------------------------------------------------------------*
           EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01  HV-TRAN-ID PIC X(16).
       01  HV-TRAN-FROM PIC X(12).
       01  HV-TRAN-TO PIC X(12).
       01  HV-TRAN-AMT PIC S9(11)V99 COMP-3.
       01  HV-TRAN-STATUS PIC X(10).
       01  HV-TRAN-DATE PIC X(10).
       01  HV-TRAN-BRANCH PIC X(6).
       01  HV-TRAN-REF PIC X(20).
       01  HV-BAL-FROM PIC S9(11)V99 COMP-3.
       01  HV-BAL-TO PIC S9(11)V99 COMP-3.
       01  HV-POST-DATE PIC X(10).
       01  HV-BATCH-ID PIC X(10).
           EXEC SQL END DECLARE SECTION END-EXEC.
      *---------------------------------------------------------------*
      * PROGRAM WORK FIELDS.                                          *
      *---------------------------------------------------------------*
       01  WS-SQLCODE PIC S9(9) COMP-5 VALUE ZERO.
       01  WS-SQLCODE-DISP PIC -ZZZZZZZZ9 VALUE ZERO.
       01  WS-EOF-FLAG PIC X VALUE "N".
           88 END-OF-CURSOR VALUE "Y".
           88 MORE-ROWS VALUE "N".
       01  WS-ROWS-READ PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-ROWS-POSTED PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-ROWS-FAILED PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-COMMITS PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-ROLLBACKS PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-NOTFOUND-COUNT PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-NEG-COUNT PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-COMMIT-FREQ PIC 9(5) COMP-5 VALUE 100.
       01  WS-SINCE-COMMIT PIC 9(5) COMP-5 VALUE ZERO.
       01  WS-RETRY-COUNT PIC 9 VALUE ZERO.
       01  WS-DISP-AMT PIC $$$,$$$,$$9.99 VALUE ZERO.
       01  WS-MESSAGE PIC X(100) VALUE SPACES.
       01  WS-JOURNAL-LINE PIC X(132) VALUE SPACES.
       01  WS-ERROR-LINE PIC X(132) VALUE SPACES.
       01  WS-PROG-NAME PIC X(8) VALUE "HTDBTRAN".
       01  WS-PAGE-NO PIC 9(5) VALUE 1.
       01  WS-LINE-COUNT PIC 9(3) VALUE 99.
       01  WS-MAX-LINES PIC 9(3) VALUE 55.
      *---------------------------------------------------------------*
      * CURSOR FOR UPDATE - LOCKS EACH QUEUED ROW FOR POSTING.        *
      *---------------------------------------------------------------*
           EXEC SQL DECLARE TRAN-CUR CURSOR FOR
             SELECT TRAN_ID, TRAN_FROM, TRAN_TO, TRAN_AMT,
                    TRAN_STATUS, TRAN_DATE, TRAN_BRANCH, TRAN_REF
               FROM HT_TRANSFER_QUEUE
              WHERE TRAN_STATUS = 'QUEUED'
                AND TRAN_BATCH = :HV-BATCH-ID
              ORDER BY TRAN_ID
              FOR UPDATE OF TRAN_STATUS, TRAN_POST_DATE
           END-EXEC.
       PROCEDURE DIVISION.
      *---------------------------------------------------------------*
      * MAINLINE - FETCH EACH QUEUED ROW, POST, COMMIT OR ROLLBACK.   *
      *---------------------------------------------------------------*
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM 1100-SET-BATCH
           PERFORM 1200-OPEN-CURSOR
           IF END-OF-CURSOR
               CONTINUE
           ELSE
               PERFORM 2000-FETCH-LOOP
           END-IF
           PERFORM 7000-FINAL-COMMIT
           PERFORM 8000-CLOSE-CURSOR
           PERFORM 9000-WRITE-SUMMARY
           PERFORM 9500-TERMINATE
           GOBACK.
       1000-INITIALIZE.
           EXEC SQL WHENEVER NOT FOUND CONTINUE END-EXEC
           MOVE "N" TO WS-EOF-FLAG
           MOVE ZERO TO WS-ROWS-READ
           MOVE ZERO TO WS-ROWS-POSTED
           MOVE ZERO TO WS-ROWS-FAILED
           MOVE ZERO TO WS-COMMITS
           MOVE ZERO TO WS-ROLLBACKS
           MOVE ZERO TO WS-NOTFOUND-COUNT
           MOVE ZERO TO WS-NEG-COUNT
           MOVE ZERO TO WS-SINCE-COMMIT
           MOVE 100 TO WS-COMMIT-FREQ
           MOVE 1 TO WS-PAGE-NO
           MOVE 99 TO WS-LINE-COUNT
           OPEN OUTPUT TRAN-JOURNAL
           OPEN OUTPUT TRAN-ERRORS
           PERFORM 1050-WRITE-HEADING
           EXIT.
       1050-WRITE-HEADING.
           MOVE SPACES TO WS-JOURNAL-LINE
           STRING "HARBOR TRUST - TRANSFER POSTING JOURNAL - "
               WS-PROG-NAME
               DELIMITED BY SIZE INTO WS-JOURNAL-LINE
           END-STRING
           WRITE TRAN-JOURNAL-REC FROM WS-JOURNAL-LINE
           MOVE SPACES TO WS-JOURNAL-LINE
           STRING "TRAN-ID  FROM  TO  AMOUNT  STATUS"
               DELIMITED BY SIZE INTO WS-JOURNAL-LINE
           END-STRING
           WRITE TRAN-JOURNAL-REC FROM WS-JOURNAL-LINE
           MOVE 2 TO WS-LINE-COUNT
           EXIT.
       1100-SET-BATCH.
           MOVE "BATCH00001" TO HV-BATCH-ID
           MOVE "0000-00-00" TO HV-POST-DATE
           EXIT.
       1200-OPEN-CURSOR.
           EXEC SQL OPEN TRAN-CUR END-EXEC
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
                   PERFORM 2200-POST-ROW
               END-IF
           END-PERFORM
           EXIT.
       2100-FETCH-ROW.
           EXEC SQL FETCH TRAN-CUR
             INTO :HV-TRAN-ID, :HV-TRAN-FROM, :HV-TRAN-TO,
                  :HV-TRAN-AMT, :HV-TRAN-STATUS, :HV-TRAN-DATE,
                  :HV-TRAN-BRANCH, :HV-TRAN-REF
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
       2200-POST-ROW.
           PERFORM 2300-VALIDATE-ROW
           IF WS-MESSAGE = SPACES
               PERFORM 3000-READ-BALANCES
           END-IF
           IF WS-MESSAGE = SPACES
               PERFORM 4000-UPDATE-QUEUE-ROW
           END-IF
           IF WS-MESSAGE = SPACES
               PERFORM 5000-POSTED
           ELSE
               PERFORM 6000-FAILED
           END-IF
           EXIT.
       2300-VALIDATE-ROW.
           MOVE SPACES TO WS-MESSAGE
           IF HV-TRAN-ID = SPACES
               MOVE "BLANK TRAN-ID" TO WS-MESSAGE
           END-IF
           IF HV-TRAN-FROM = SPACES
               MOVE "BLANK FROM-ACCT" TO WS-MESSAGE
           END-IF
           IF HV-TRAN-TO = SPACES
               MOVE "BLANK TO-ACCT" TO WS-MESSAGE
           END-IF
           IF HV-TRAN-FROM = HV-TRAN-TO
               MOVE "FROM EQUALS TO" TO WS-MESSAGE
           END-IF
           IF HV-TRAN-AMT <= ZERO
               MOVE "NON-POSITIVE AMOUNT" TO WS-MESSAGE
           END-IF
           IF HV-TRAN-STATUS NOT = "QUEUED    "
               MOVE "NOT QUEUED" TO WS-MESSAGE
           END-IF
           EXIT.
       3000-READ-BALANCES.
           MOVE HV-TRAN-FROM TO HV-BAL-FROM
           MOVE HV-TRAN-TO TO HV-BAL-TO
           EXEC SQL SELECT ACCT_BALANCE INTO :HV-BAL-FROM
             FROM HT_ACCOUNT_MASTER
            WHERE ACCT_ID = :HV-TRAN-FROM
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           EVALUATE SQLCODE
             WHEN 0
               CONTINUE
             WHEN 100
               MOVE "FROM-ACCT NOT FOUND" TO WS-MESSAGE
             WHEN OTHER
               MOVE "FROM-ACCT SELECT ERROR" TO WS-MESSAGE
               PERFORM 9200-NEGATIVE-SQLCODE
           END-EVALUATE
           IF WS-MESSAGE NOT = SPACES
               EXIT
           END-IF
           EXEC SQL SELECT ACCT_BALANCE INTO :HV-BAL-TO
             FROM HT_ACCOUNT_MASTER
            WHERE ACCT_ID = :HV-TRAN-TO
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           EVALUATE SQLCODE
             WHEN 0
               CONTINUE
             WHEN 100
               MOVE "TO-ACCT NOT FOUND" TO WS-MESSAGE
             WHEN OTHER
               MOVE "TO-ACCT SELECT ERROR" TO WS-MESSAGE
               PERFORM 9200-NEGATIVE-SQLCODE
           END-EVALUATE
           IF WS-MESSAGE NOT = SPACES
               EXIT
           END-IF
           IF HV-BAL-FROM < HV-TRAN-AMT
               MOVE "INSUFFICIENT FUNDS" TO WS-MESSAGE
           END-IF
           EXIT.
       4000-UPDATE-QUEUE-ROW.
           EXEC SQL UPDATE HT_TRANSFER_QUEUE
              SET TRAN_STATUS = 'POSTED',
                  TRAN_POST_DATE = :HV-POST-DATE
            WHERE CURRENT OF TRAN-CUR
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           EVALUATE SQLCODE
             WHEN 0
               CONTINUE
             WHEN 100
               MOVE "UPDATE NOT FOUND" TO WS-MESSAGE
               ADD 1 TO WS-NOTFOUND-COUNT
             WHEN OTHER
               MOVE "UPDATE FAILED" TO WS-MESSAGE
               PERFORM 9200-NEGATIVE-SQLCODE
           END-EVALUATE
           EXIT.
       5000-POSTED.
           ADD 1 TO WS-ROWS-POSTED
           ADD 1 TO WS-SINCE-COMMIT
           PERFORM 5100-WRITE-JOURNAL
           IF WS-SINCE-COMMIT >= WS-COMMIT-FREQ
               PERFORM 7100-COMMIT-WORK
           END-IF
           EXIT.
       5100-WRITE-JOURNAL.
           IF WS-LINE-COUNT >= WS-MAX-LINES
               PERFORM 5200-PAGE-BREAK
           END-IF
           MOVE SPACES TO WS-JOURNAL-LINE
           MOVE HV-TRAN-AMT TO WS-DISP-AMT
           STRING HV-TRAN-ID " " HV-TRAN-FROM " " HV-TRAN-TO " "
               WS-DISP-AMT " POSTED"
               DELIMITED BY SIZE INTO WS-JOURNAL-LINE
           END-STRING
           WRITE TRAN-JOURNAL-REC FROM WS-JOURNAL-LINE
           ADD 1 TO WS-LINE-COUNT
           EXIT.
       5200-PAGE-BREAK.
           ADD 1 TO WS-PAGE-NO
           MOVE ZERO TO WS-LINE-COUNT
           PERFORM 1050-WRITE-HEADING
           EXIT.
       6000-FAILED.
           ADD 1 TO WS-ROWS-FAILED
           PERFORM 6100-MARK-FAILED
           PERFORM 7200-ROLLBACK-WORK
           PERFORM 6200-LOG-FAILURE
           EXIT.
       6100-MARK-FAILED.
           EXEC SQL UPDATE HT_TRANSFER_QUEUE
              SET TRAN_STATUS = 'FAILED'
            WHERE CURRENT OF TRAN-CUR
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           EVALUATE SQLCODE
             WHEN 0
               EXEC SQL COMMIT END-EXEC
               ADD 1 TO WS-COMMITS
             WHEN 100
               ADD 1 TO WS-NOTFOUND-COUNT
             WHEN OTHER
               PERFORM 9200-NEGATIVE-SQLCODE
           END-EVALUATE
           EXIT.
       6200-LOG-FAILURE.
           MOVE SPACES TO WS-ERROR-LINE
           STRING "FAILED " HV-TRAN-ID " " WS-MESSAGE
               DELIMITED BY SIZE INTO WS-ERROR-LINE
           END-STRING
           WRITE TRAN-ERRORS-REC FROM WS-ERROR-LINE
           EXIT.
       7000-FINAL-COMMIT.
           IF WS-SINCE-COMMIT > ZERO
               PERFORM 7100-COMMIT-WORK
           END-IF
           EXIT.
       7100-COMMIT-WORK.
           EXEC SQL COMMIT END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           EVALUATE SQLCODE
             WHEN 0
               ADD 1 TO WS-COMMITS
               MOVE ZERO TO WS-SINCE-COMMIT
             WHEN OTHER
               PERFORM 9100-SQL-FAILURE
           END-EVALUATE
           EXIT.
       7200-ROLLBACK-WORK.
           EXEC SQL ROLLBACK END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           EVALUATE SQLCODE
             WHEN 0
               ADD 1 TO WS-ROLLBACKS
               MOVE ZERO TO WS-SINCE-COMMIT
             WHEN OTHER
               PERFORM 9100-SQL-FAILURE
           END-EVALUATE
           EXIT.
       8000-CLOSE-CURSOR.
           EXEC SQL CLOSE TRAN-CUR END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           EVALUATE SQLCODE
             WHEN 0
               CONTINUE
             WHEN OTHER
               PERFORM 9100-SQL-FAILURE
           END-EVALUATE
           EXIT.
       9000-WRITE-SUMMARY.
           MOVE SPACES TO WS-JOURNAL-LINE
           STRING "READ=" WS-ROWS-READ " POSTED=" WS-ROWS-POSTED
               " FAILED=" WS-ROWS-FAILED
               DELIMITED BY SIZE INTO WS-JOURNAL-LINE
           END-STRING
           WRITE TRAN-JOURNAL-REC FROM WS-JOURNAL-LINE
           MOVE SPACES TO WS-JOURNAL-LINE
           STRING "COMMITS=" WS-COMMITS " ROLLBACKS=" WS-ROLLBACKS
               " NEG=" WS-NEG-COUNT
               DELIMITED BY SIZE INTO WS-JOURNAL-LINE
           END-STRING
           WRITE TRAN-JOURNAL-REC FROM WS-JOURNAL-LINE
           EXIT.
       9100-SQL-FAILURE.
           MOVE SQLCODE TO WS-SQLCODE-DISP
           MOVE SPACES TO WS-ERROR-LINE
           STRING "SQL FAILURE CODE=" WS-SQLCODE-DISP
               DELIMITED BY SIZE INTO WS-ERROR-LINE
           END-STRING
           WRITE TRAN-ERRORS-REC FROM WS-ERROR-LINE
           ADD 1 TO WS-NEG-COUNT
           EXIT.
       9200-NEGATIVE-SQLCODE.
           MOVE SQLCODE TO WS-SQLCODE-DISP
           MOVE SPACES TO WS-ERROR-LINE
           STRING "NEG SQLCODE=" WS-SQLCODE-DISP " TRAN=" HV-TRAN-ID
               DELIMITED BY SIZE INTO WS-ERROR-LINE
           END-STRING
           WRITE TRAN-ERRORS-REC FROM WS-ERROR-LINE
           ADD 1 TO WS-NEG-COUNT
           MOVE "DB2 ERROR" TO WS-MESSAGE
           EXIT.
       9500-TERMINATE.
           CLOSE TRAN-JOURNAL
           CLOSE TRAN-ERRORS
           EXIT.
