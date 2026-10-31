       IDENTIFICATION DIVISION.
       PROGRAM-ID. HTDATEUT.
      * Fictional Harbor Trust date utility. Synthetic logic only.
      * Called via CALL USING BY REFERENCE and BY CONTENT.
      * IBM Enterprise COBOL subprogram.
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-QTY PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-IDX PIC 9(4) COMP-5 VALUE ZERO.
       01  WS-YEAR PIC 9(4) VALUE ZERO.
       01  WS-MONTH PIC 9(2) VALUE ZERO.
       01  WS-DAY PIC 9(2) VALUE ZERO.
       01  WS-LEAP PIC X VALUE "N".
           88 IS-LEAP VALUE "Y".
       01  WS-QUOTIENT PIC 9(4) COMP-5 VALUE ZERO.
       01  WS-REMAINDER PIC 9(4) COMP-5 VALUE ZERO.
       01  WS-MONTH-TABLE.
          05 FILLER PIC X(24) VALUE "312831303130313130313031".
       01  WS-MONTH-LEN REDEFINES WS-MONTH-TABLE.
          05 WS-MDAYS OCCURS 12 TIMES PIC 9(2).
       01  WS-DAY-COUNT PIC 9(7) COMP-5 VALUE ZERO.
       01  WS-BASIS-WORK PIC 9(3) COMP-5 VALUE 365.
       01  WS-VALID-FLAG PIC X VALUE "Y".
           88 DATE-IS-VALID VALUE "Y".
       LINKAGE SECTION.
       01  LS-DATE-YYYYMMDD PIC 9(8).
       01  LS-DAY-BASIS PIC 9(3) COMP-5.
       PROCEDURE DIVISION USING BY REFERENCE LS-DATE-YYYYMMDD
           BY REFERENCE LS-DAY-BASIS.
       0000-MAIN.
           PERFORM 1000-SPLIT-DATE
           PERFORM 2000-CHECK-LEAP-YEAR
           PERFORM 3000-VALIDATE-DATE
           PERFORM 4000-NORMALIZE-BASIS
           PERFORM 5000-COMPUTE-DAY-COUNT
           GOBACK.
       1000-SPLIT-DATE.
           MOVE LS-DATE-YYYYMMDD(1:4) TO WS-YEAR
           MOVE LS-DATE-YYYYMMDD(5:2) TO WS-MONTH
           MOVE LS-DATE-YYYYMMDD(7:2) TO WS-DAY
           IF WS-MONTH < 01 OR > 12
               MOVE "N" TO WS-VALID-FLAG
           END-IF
           IF WS-DAY < 01 OR > 31
               MOVE "N" TO WS-VALID-FLAG
           END-IF.
       2000-CHECK-LEAP-YEAR.
           DIVIDE WS-YEAR BY 4 GIVING WS-QUOTIENT
               REMAINDER WS-REMAINDER
           END-DIVIDE
           IF WS-REMAINDER = ZERO
               MOVE "Y" TO WS-LEAP
           ELSE
               MOVE "N" TO WS-LEAP
           END-IF
           DIVIDE WS-YEAR BY 100 GIVING WS-QUOTIENT
               REMAINDER WS-REMAINDER
           END-DIVIDE
           IF WS-REMAINDER = ZERO
               MOVE "N" TO WS-LEAP
           END-IF
           DIVIDE WS-YEAR BY 400 GIVING WS-QUOTIENT
               REMAINDER WS-REMAINDER
           END-DIVIDE
           IF WS-REMAINDER = ZERO
               MOVE "Y" TO WS-LEAP
           END-IF.
       3000-VALIDATE-DATE.
           IF WS-MONTH >= 01 AND <= 12
               IF WS-DAY > WS-MDAYS(WS-MONTH)
                   IF NOT (WS-MONTH = 02 AND IS-LEAP
                       AND WS-DAY = 29)
                       MOVE "N" TO WS-VALID-FLAG
                   END-IF
               END-IF
           END-IF
           IF NOT DATE-IS-VALID
               MOVE 4 TO RETURN-CODE
           ELSE
               MOVE ZERO TO RETURN-CODE
           END-IF.
       4000-NORMALIZE-BASIS.
           MOVE LS-DAY-BASIS TO WS-BASIS-WORK
           EVALUATE WS-BASIS-WORK
               WHEN 360 CONTINUE
               WHEN 365 CONTINUE
               WHEN 366 CONTINUE
               WHEN OTHER MOVE 365 TO WS-BASIS-WORK
           END-EVALUATE
           IF IS-LEAP
               MOVE 366 TO WS-BASIS-WORK
           END-IF.
       5000-COMPUTE-DAY-COUNT.
           MOVE ZERO TO WS-DAY-COUNT
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX >= WS-MONTH
               ADD WS-MDAYS(WS-IDX) TO WS-DAY-COUNT
           END-PERFORM
           ADD WS-DAY TO WS-DAY-COUNT
           IF WS-MONTH > 2 AND IS-LEAP
               ADD 1 TO WS-DAY-COUNT
           END-IF
           MOVE WS-DAY-COUNT TO WS-QTY.
