>>SOURCE FORMAT FREE
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HTDBS.
      *> DB2 SQL module: Statement detail retrieval; DCLGEN contract is synthetic.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
           EXEC SQL INCLUDE SQLCA END-EXEC.
       01 WS-ACCOUNT PIC X(12).
       01 WS-BALANCE PIC S9(9)V99 COMP-3.
       01 WS-AMOUNT PIC S9(9)V99 COMP-3.
       01 WS-RATE PIC 9V9999 COMP-3.
       01 WS-STATUS PIC X(8).
       01 WS-SQLCODE PIC S9(9) COMP-5.
       01 WS-EOF PIC X VALUE "N".
       01 WS-ROWS PIC 9(9) COMP-5 VALUE ZERO.
       01 WS-REJECTS PIC 9(9) COMP-5 VALUE ZERO.
       01 WS-RETRY PIC 9 VALUE ZERO.
       01 WS-SAVEPOINT PIC X(16) VALUE 'HTSAVE'.
       01 WS-MESSAGE PIC X(80).
       EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01 HV-ACCOUNT PIC X(12).
       01 HV-BALANCE DECIMAL(11,2).
       01 HV-AMOUNT DECIMAL(11,2).
       01 HV-RATE DECIMAL(5,4).
       01 HV-STATUS CHAR(8).
       EXEC SQL END DECLARE SECTION END-EXEC.
       EXEC SQL DECLARE HT-CUR CURSOR FOR
         SELECT ACCOUNT_ID, BALANCE, STATUS
           FROM HT_ACTIVITY
          WHERE STATUS IN ('ACTIVE', 'DORMANT')
          ORDER BY ACCOUNT_ID
       END-EXEC.
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-OPEN-CURSOR
           PERFORM UNTIL WS-EOF = "Y"
               PERFORM 2000-FETCH-ROW
               IF WS-EOF NOT = "Y"
                   PERFORM 3000-APPLY-ROW
               END-IF
           END-PERFORM
           PERFORM 8000-CLOSE-CURSOR
           PERFORM 9000-COMMIT-OR-ROLLBACK
           GOBACK.
       1000-OPEN-CURSOR.
           EXEC SQL OPEN HT-CUR END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           EVALUATE SQLCODE
             WHEN 0 CONTINUE
             WHEN OTHER PERFORM 9100-SQL-FAILURE
           END-EVALUATE.
       2000-FETCH-ROW.
           EXEC SQL FETCH HT-CUR
             INTO :HV-ACCOUNT, :HV-BALANCE, :HV-STATUS
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           EVALUATE SQLCODE
             WHEN 0 ADD 1 TO WS-ROWS
             WHEN 100 MOVE "Y" TO WS-EOF
             WHEN OTHER PERFORM 9100-SQL-FAILURE
           END-EVALUATE.
       3000-APPLY-ROW.
           MOVE HV-ACCOUNT TO WS-ACCOUNT
           MOVE HV-BALANCE TO WS-BALANCE
           MOVE HV-STATUS TO WS-STATUS
           PERFORM 3100-VALIDATE-HOST-VARIABLES
           IF WS-REJECTS = ZERO
               PERFORM 3200-POST-UPDATE
           END-IF.
       3100-VALIDATE-HOST-VARIABLES.
           IF HV-ACCOUNT = SPACES
               ADD 1 TO WS-REJECTS
               MOVE "NULL/BLANK ACCOUNT KEY" TO WS-MESSAGE
           END-IF
           IF WS-BALANCE < -999999999.99
               ADD 1 TO WS-REJECTS
               MOVE "NEGATIVE LIMIT EXCEEDED" TO WS-MESSAGE
           END-IF
           IF WS-STATUS NOT = "ACTIVE" AND WS-STATUS NOT = "DORMANT"
               ADD 1 TO WS-REJECTS
               MOVE "STATUS OUTSIDE CURSOR DOMAIN" TO WS-MESSAGE
           END-IF.
       3200-POST-UPDATE.
           COMPUTE WS-AMOUNT ROUNDED = WS-BALANCE * WS-RATE
             ON SIZE ERROR PERFORM 9200-ARITHMETIC-FAILURE
           END-COMPUTE
           MOVE WS-AMOUNT TO HV-AMOUNT
           MOVE WS-ACCOUNT TO HV-ACCOUNT
           EXEC SQL UPDATE HT_ACTIVITY
                SET BALANCE = BALANCE + :HV-AMOUNT
              WHERE ACCOUNT_ID = :HV-ACCOUNT
           END-EXEC
           EVALUATE SQLCODE
             WHEN 0 CONTINUE
             WHEN 100 ADD 1 TO WS-REJECTS
             WHEN OTHER PERFORM 9100-SQL-FAILURE
           END-EVALUATE.
       8000-CLOSE-CURSOR.
           EXEC SQL CLOSE HT-CUR END-EXEC
           IF SQLCODE NOT = ZERO PERFORM 9100-SQL-FAILURE END-IF.
       9000-COMMIT-OR-ROLLBACK.
           IF WS-REJECTS = ZERO
               EXEC SQL COMMIT END-EXEC
           ELSE
               EXEC SQL ROLLBACK END-EXEC
           END-IF
           IF SQLCODE NOT = ZERO PERFORM 9100-SQL-FAILURE END-IF.
       9100-SQL-FAILURE.
           DISPLAY "SQL ERROR CODE=" SQLCODE
           DISPLAY "SQLSTATE=" SQLSTATE
           DISPLAY "SQLERRMC=" SQLERRMC
           EXEC SQL ROLLBACK END-EXEC
           MOVE 12 TO RETURN-CODE
           MOVE "DB2 OPERATION FAILED" TO WS-MESSAGE.
       9200-ARITHMETIC-FAILURE.
           DISPLAY "DECIMAL OVERFLOW ACCOUNT=" WS-ACCOUNT
           ADD 1 TO WS-REJECTS.
       5000-SQL-REVIEW-CHECK-01.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5010-SQL-REVIEW-CHECK-02.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5020-SQL-REVIEW-CHECK-03.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5030-SQL-REVIEW-CHECK-04.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5040-SQL-REVIEW-CHECK-05.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5050-SQL-REVIEW-CHECK-06.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5060-SQL-REVIEW-CHECK-07.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5070-SQL-REVIEW-CHECK-08.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5080-SQL-REVIEW-CHECK-09.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5090-SQL-REVIEW-CHECK-10.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5100-SQL-REVIEW-CHECK-11.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5110-SQL-REVIEW-CHECK-12.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5120-SQL-REVIEW-CHECK-13.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5130-SQL-REVIEW-CHECK-14.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5140-SQL-REVIEW-CHECK-15.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5150-SQL-REVIEW-CHECK-16.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5160-SQL-REVIEW-CHECK-17.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5170-SQL-REVIEW-CHECK-18.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5180-SQL-REVIEW-CHECK-19.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5190-SQL-REVIEW-CHECK-20.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5200-SQL-REVIEW-CHECK-21.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5210-SQL-REVIEW-CHECK-22.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5220-SQL-REVIEW-CHECK-23.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5230-SQL-REVIEW-CHECK-24.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
       5240-SQL-REVIEW-CHECK-25.
           IF WS-SQLCODE = 100
               CONTINUE
           ELSE
               IF WS-ROWS > ZERO
                   CONTINUE
               END-IF
           END-IF.
