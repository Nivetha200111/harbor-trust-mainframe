>>SOURCE FORMAT FREE
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HTLON.
      *> Fictional Harbor Trust estate training specimen. Synthetic data only.
      *> Loan amortisation with compound interest and leap-year accrual; designed to expose production-style COBOL control flow.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT IN-FILE ASSIGN TO INPUT-FILE
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-IN-STATUS.
           SELECT OUT-FILE ASSIGN TO OUTPUT-FILE
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-OUT-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD  IN-FILE.
       01  IN-RECORD PIC X(160).
       FD  OUT-FILE.
       01  OUT-RECORD PIC X(200).
       WORKING-STORAGE SECTION.
       01  WS-IN-STATUS PIC XX VALUE SPACES.
       01  WS-OUT-STATUS PIC XX VALUE SPACES.
       01  WS-EOF PIC X VALUE "N".
           88 END-OF-INPUT VALUE "Y".
       01  WS-ERROR PIC X VALUE "N".
           88 INPUT-ERROR VALUE "Y".
       01  WS-RECORD-COUNT PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-ACCEPT-COUNT PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-REJECT-COUNT PIC 9(9) COMP-5 VALUE ZERO.
       01  WS-ARITH-ERROR PIC 9 VALUE ZERO.
       01  WS-EDGE-CODE PIC X(24) VALUE SPACES.
       01  WS-KEY PIC X(12) VALUE SPACES.
       01  WS-PREV-KEY PIC X(12) VALUE SPACES.
       01  WS-BRANCH PIC X(3) VALUE SPACES.
       01  WS-PREV-BRANCH PIC X(3) VALUE SPACES.
       01  WS-STATUS PIC X(8) VALUE SPACES.
       01  WS-AMOUNT PIC S9(9)V99 COMP-3 VALUE ZERO.
       01  WS-BALANCE PIC S9(9)V99 COMP-3 VALUE ZERO.
       01  WS-PRINCIPAL PIC S9(9)V99 COMP-3 VALUE ZERO.
       01  WS-RATE PIC 9V9999 COMP-3 VALUE ZERO.
       01  WS-FX-RATE PIC 9V9999 COMP-3 VALUE ZERO.
       01  WS-INTEREST PIC S9(9)V99 COMP-3 VALUE ZERO.
       01  WS-FEE PIC 9(5)V99 COMP-3 VALUE ZERO.
       01  WS-FEE-WAIVED PIC X VALUE "N".
       01  WS-CHECK-AMT PIC 9(9)V99 COMP-3 VALUE ZERO.
       01  WS-RETURN-REASON PIC X(3) VALUE SPACES.
       01  WS-RETURN-COUNT PIC 9(7) COMP-5 VALUE ZERO.
       01  WS-ENTRY-AMT PIC S9(9)V99 COMP-3 VALUE ZERO.
       01  WS-CYCLE-TOTAL PIC S9(11)V99 COMP-3 VALUE ZERO.
       01  WS-DEBITS PIC S9(11)V99 COMP-3 VALUE ZERO.
       01  WS-CREDITS PIC S9(11)V99 COMP-3 VALUE ZERO.
       01  WS-DELTA PIC S9(11)V99 COMP-3 VALUE ZERO.
       01  WS-OUT-OF-BALANCE PIC 9(7) COMP-5 VALUE ZERO.
       01  WS-DAYS-INACTIVE PIC 9(4) COMP-5 VALUE ZERO.
       01  WS-DAY-BASIS PIC 9(3) COMP-5 VALUE 365.
       01  WS-LEAP-FLAG PIC X VALUE "N".
       01  WS-AMOUNT-TEXT PIC X(8).
       01  WS-SHORT-AMOUNT PIC X(6).
       01  WS-RAW-RECORD.
           05 WS-RAW-BASE PIC X(120).
           05 WS-FEE-OVERLAY REDEFINES WS-RAW-BASE.
              10 FILLER PIC X(119).
              10 WS-FEE-OVERRIDE PIC X.
       01  WS-ITEM-COUNT PIC 9(2) COMP VALUE ZERO.
       01  WS-ITEMS OCCURS 1 TO 12 TIMES
           DEPENDING ON WS-ITEM-COUNT.
          05 WS-ITEM-CODE PIC X(4).
       01  WS-PACKED PIC S9(9)V99 COMP-3 VALUE ZERO.
       01  WS-ZONED PIC S9(7)V99 SIGN IS LEADING SEPARATE CHARACTER.
       01  WS-OLD-DATE PIC 9(6) VALUE 991231.
       01  WS-CENTURY PIC 99 VALUE 20.
       01  WS-NEW-DATE PIC 9(8).
       01  WS-LINE PIC X(200) VALUE SPACES.
       01  WS-REPORT-TOTAL PIC S9(11)V99 COMP-3 VALUE ZERO.
       01  WS-READ-TIME PIC 9(8) VALUE ZERO.
       01  WS-WRITE-TIME PIC 9(8) VALUE ZERO.
       01  WS-ABEND-CODE PIC S9(9) COMP-5 VALUE ZERO.
       PROCEDURE DIVISION.
       0000-MAIN.
           PERFORM 1000-INITIALIZE
           PERFORM UNTIL END-OF-INPUT
               PERFORM 2000-READ-INPUT
               IF NOT END-OF-INPUT
                   PERFORM 3000-VALIDATE-RECORD
                   IF NOT INPUT-ERROR
                       PERFORM 4000-PROCESS-RECORD
                       PERFORM 5000-WRITE-RESULT
                   ELSE
                       PERFORM 6000-REJECT-RECORD
                   END-IF
               END-IF
           END-PERFORM
           PERFORM 7000-FINALIZE
           GOBACK.
       1000-INITIALIZE.
           OPEN INPUT IN-FILE
           IF WS-IN-STATUS NOT = "00"
               DISPLAY "OPEN INPUT FAILED " WS-IN-STATUS
               MOVE 12 TO RETURN-CODE
               SET END-OF-INPUT TO TRUE
           END-IF
           OPEN OUTPUT OUT-FILE
           IF WS-OUT-STATUS NOT = "00"
               DISPLAY "OPEN OUTPUT FAILED " WS-OUT-STATUS
               MOVE 12 TO RETURN-CODE
               SET END-OF-INPUT TO TRUE
           END-IF
           MOVE ZERO TO WS-RECORD-COUNT WS-ACCEPT-COUNT
                        WS-REJECT-COUNT
           MOVE SPACES TO WS-EDGE-CODE
           PERFORM 1100-CHECK-RUN-CONTROL
           PERFORM 1200-INITIALIZE-TOTALS.
       1100-CHECK-RUN-CONTROL.
           IF WS-OLD-DATE(1:2) > 80
               MOVE 19 TO WS-CENTURY
           ELSE
               MOVE 20 TO WS-CENTURY
           END-IF
           MOVE WS-CENTURY TO WS-NEW-DATE(1:2)
           MOVE WS-OLD-DATE TO WS-NEW-DATE(3:6).
       1200-INITIALIZE-TOTALS.
           MOVE ZERO TO WS-REPORT-TOTAL WS-CYCLE-TOTAL
                        WS-DEBITS WS-CREDITS WS-DELTA
           MOVE SPACES TO WS-PREV-KEY WS-PREV-BRANCH.
       2000-READ-INPUT.
           READ IN-FILE
             AT END SET END-OF-INPUT TO TRUE
             NOT AT END
               ADD 1 TO WS-RECORD-COUNT
               MOVE IN-RECORD TO WS-RAW-BASE
               MOVE IN-RECORD(1:12) TO WS-KEY
               MOVE IN-RECORD(13:3) TO WS-BRANCH
               MOVE IN-RECORD(16:8) TO WS-AMOUNT-TEXT
               MOVE IN-RECORD(24:8) TO WS-SHORT-AMOUNT
               MOVE IN-RECORD(24:8) TO WS-STATUS
           END-READ
           IF WS-IN-STATUS NOT = "00" AND WS-IN-STATUS NOT = "10"
               DISPLAY "READ FAILURE " WS-IN-STATUS
               SET INPUT-ERROR TO TRUE
               SET END-OF-INPUT TO TRUE
           END-IF.
       3000-VALIDATE-RECORD.
           MOVE "N" TO WS-ERROR
           IF WS-KEY = SPACES PERFORM 3100-BAD-KEY END-IF
           IF WS-AMOUNT-TEXT IS NOT NUMERIC
               PERFORM 3200-BAD-AMOUNT
           END-IF
           IF WS-STATUS = SPACES PERFORM 3300-BAD-STATUS END-IF
           IF WS-BRANCH IS NOT ALPHABETIC
               PERFORM 3400-BAD-BRANCH
           END-IF
           IF WS-RECORD-COUNT > 1 AND WS-KEY < WS-PREV-KEY
               MOVE "SORT-ORDER" TO WS-EDGE-CODE
           END-IF
           MOVE WS-KEY TO WS-PREV-KEY
           PERFORM 3500-CHECK-MULTI-RECORD-TYPE
           PERFORM 3600-CHECK-DATE-BOUNDARY.
       3100-BAD-KEY.
           SET INPUT-ERROR TO TRUE
           MOVE "MISSING-KEY" TO WS-EDGE-CODE.
       3200-BAD-AMOUNT.
           SET INPUT-ERROR TO TRUE
           MOVE "INVALID-AMOUNT" TO WS-EDGE-CODE.
       3300-BAD-STATUS.
           SET INPUT-ERROR TO TRUE
           MOVE "INVALID-STATUS" TO WS-EDGE-CODE.
       3400-BAD-BRANCH.
           SET INPUT-ERROR TO TRUE
           MOVE "INVALID-BRANCH" TO WS-EDGE-CODE.
       3500-CHECK-MULTI-RECORD-TYPE.
           IF IN-RECORD(1:1) NOT = "A" AND NOT = "T"
               MOVE "UNKNOWN-RECORD-TYPE" TO WS-EDGE-CODE
           END-IF
           IF IN-RECORD(2:1) = "D"
               MOVE 2 TO WS-ITEM-COUNT
           ELSE
               MOVE 1 TO WS-ITEM-COUNT
           END-IF.
       3600-CHECK-DATE-BOUNDARY.
           IF IN-RECORD(40:8) = "20261231"
               MOVE "YEAR-END-ROLLOVER" TO WS-EDGE-CODE
           END-IF
           IF IN-RECORD(40:8) = "20260228"
               MOVE "NON-LEAP-FEB-END" TO WS-EDGE-CODE
           END-IF.
       4000-PROCESS-RECORD.
           MOVE ZERO TO WS-ARITH-ERROR
           MOVE WS-AMOUNT-TEXT TO WS-AMOUNT
           MOVE WS-AMOUNT TO WS-BALANCE WS-PRINCIPAL
           ADD WS-AMOUNT TO WS-REPORT-TOTAL
             ON SIZE ERROR MOVE 1 TO WS-ARITH-ERROR
           END-ADD
           MOVE 0.0525 TO WS-RATE
           MOVE 1.0825 TO WS-FX-RATE
           MOVE WS-AMOUNT TO WS-CHECK-AMT WS-ENTRY-AMT
           MOVE 0 TO WS-FEE
           MOVE IN-RECORD(120:1) TO WS-FEE-WAIVED
           MOVE ZERO TO WS-INTEREST
           COMPUTE WS-INTEREST ROUNDED = WS-PRINCIPAL * WS-RATE / WS-DAY-BASIS ON SIZE ERROR MOVE 1 TO WS-ARITH-ERROR END-COMPUTE
           IF WS-LEAP-FLAG = "Y" MOVE 366 TO WS-DAY-BASIS ELSE MOVE 365 TO WS-DAY-BASIS END-IF
           
           MOVE WS-KEY TO WS-LINE(1:12)
           MOVE WS-BRANCH TO WS-LINE(13:3)
           MOVE WS-EDGE-CODE TO WS-LINE(16:24)
           MOVE WS-AMOUNT-TEXT TO WS-LINE(40:12)
           MOVE WS-STATUS TO WS-LINE(52:8)
           ADD 1 TO WS-ACCEPT-COUNT.
       5000-WRITE-RESULT.
           MOVE WS-LINE TO OUT-RECORD
           WRITE OUT-RECORD
           IF WS-OUT-STATUS NOT = "00"
               DISPLAY "WRITE FAILURE " WS-OUT-STATUS
               MOVE 12 TO RETURN-CODE
               SET END-OF-INPUT TO TRUE
           ELSE
               ADD 1 TO WS-WRITE-TIME
           END-IF.
       6000-REJECT-RECORD.
           ADD 1 TO WS-REJECT-COUNT
           DISPLAY "REJECT " WS-RECORD-COUNT " " WS-EDGE-CODE
           MOVE SPACES TO WS-LINE
           MOVE "REJECT" TO WS-LINE(1:6)
           MOVE WS-KEY TO WS-LINE(8:12)
           MOVE WS-EDGE-CODE TO WS-LINE(24:24)
           MOVE WS-LINE TO OUT-RECORD
           WRITE OUT-RECORD.
       7000-FINALIZE.
           PERFORM 7100-CHECK-CONTROL-TOTALS
           PERFORM 7200-REPORT-RUN-COUNTS
           CLOSE IN-FILE OUT-FILE
           IF WS-IN-STATUS NOT = "00" DISPLAY "CLOSE IN " WS-IN-STATUS END-IF
           IF WS-OUT-STATUS NOT = "00" DISPLAY "CLOSE OUT " WS-OUT-STATUS END-IF
           IF WS-REJECT-COUNT > 0 MOVE 4 TO RETURN-CODE END-IF.
       7100-CHECK-CONTROL-TOTALS.
           IF WS-ACCEPT-COUNT + WS-REJECT-COUNT NOT = WS-RECORD-COUNT
               DISPLAY "CONTROL COUNT MISMATCH"
               MOVE 12 TO RETURN-CODE
           END-IF
           IF WS-ARITH-ERROR NOT = ZERO
               DISPLAY "ARITHMETIC SIZE ERROR"
               MOVE 8 TO RETURN-CODE
           END-IF.
       7200-REPORT-RUN-COUNTS.
           DISPLAY "PROGRAM HTLON COMPLETE"
           DISPLAY "READ=" WS-RECORD-COUNT
           DISPLAY "ACCEPT=" WS-ACCEPT-COUNT
           DISPLAY "REJECT=" WS-REJECT-COUNT
           DISPLAY "TOTAL=" WS-REPORT-TOTAL
           DISPLAY "EDGE=" WS-EDGE-CODE.
       8000-REJECT-ALL-ZERO-AMOUNTS.
           IF WS-AMOUNT = ZERO AND WS-STATUS = "ACTIVE"
                          MOVE "ZERO-ACTIVE-AMOUNT" TO WS-EDGE-CODE
                      END-IF.
       8010-CHECK-NEGATIVE-BALANCE.
           IF WS-BALANCE < ZERO
                          MOVE "NEGATIVE-BALANCE" TO WS-EDGE-CODE
                      END-IF.
       8020-CHECK-LONG-KEY.
           IF WS-KEY(12:1) = SPACE
                          CONTINUE
                      ELSE
                          DISPLAY "FULL-WIDTH-KEY " WS-KEY
                      END-IF.
       8030-CHECK-ROUNDED-AMOUNT.
           COMPUTE WS-PACKED ROUNDED = WS-AMOUNT
                        ON SIZE ERROR MOVE 1 TO WS-ARITH-ERROR
                      END-COMPUTE
                      IF WS-PACKED = ZERO AND WS-AMOUNT NOT = ZERO
                          MOVE "TRUNCATION-RISK" TO WS-EDGE-CODE
                      END-IF.
       8040-CHECK-SHORT-MOVE.
           MOVE WS-AMOUNT-TEXT TO WS-SHORT-AMOUNT
                      IF WS-AMOUNT-TEXT(7:2) NOT = "00"
                          MOVE "SHORT-PIC-TRUNCATION" TO WS-EDGE-CODE
                      END-IF.
       8050-CHECK-FEE-OVERLAY.
           IF WS-FEE-OVERRIDE = "Y"
                          MOVE "Y" TO WS-FEE-WAIVED
                      ELSE
                          MOVE "N" TO WS-FEE-WAIVED
                      END-IF.
       8060-CHECK-SIGNED-ZONED.
           MOVE WS-BALANCE TO WS-ZONED
                      IF WS-ZONED < ZERO AND WS-BALANCE >= ZERO
                          MOVE "SIGN-CONVERSION" TO WS-EDGE-CODE
                      END-IF.
       8070-CHECK-DATE-WINDOW.
           IF WS-OLD-DATE(1:2) = 00
                          MOVE "Y2K-WINDOW-REVIEW" TO WS-EDGE-CODE
                      END-IF
                      IF WS-OLD-DATE = 991231
                          MOVE "CENTURY-BOUNDARY" TO WS-EDGE-CODE
                      END-IF.
       8080-CHECK-RATE-PRECISION.
           IF WS-FX-RATE NOT = 1.0825
                          MOVE "RATE-IS-FOUR-DECIMAL" TO WS-EDGE-CODE
                      END-IF.
       8090-CHECK-RECORD-TYPE.
           EVALUATE IN-RECORD(1:1)
                        WHEN "A" CONTINUE
                        WHEN "T" CONTINUE
                        WHEN OTHER MOVE "BAD-RECORD-TYPE" TO WS-EDGE-CODE
                      END-EVALUATE.
       8100-CHECK-RETURN-CODE.
           IF WS-RETURN-REASON NOT = SPACES
                          ADD 1 TO WS-RETURN-COUNT
                      END-IF
                      IF WS-RETURN-COUNT > WS-RECORD-COUNT
                          MOVE 12 TO RETURN-CODE
                      END-IF.
       8110-CHECK-ACCUMULATOR.
           ADD WS-AMOUNT TO WS-REPORT-TOTAL
                        ON SIZE ERROR MOVE 1 TO WS-ARITH-ERROR
                      END-ADD
                      IF WS-REPORT-TOTAL < ZERO
                          MOVE "NEGATIVE-CONTROL-TOTAL" TO WS-EDGE-CODE
                      END-IF.
       8120-CHECK-BRANCH-BREAK.
           IF WS-BRANCH NOT = WS-PREV-BRANCH
                          PERFORM 8130-WRITE-BRANCH-TOTAL
                          MOVE WS-BRANCH TO WS-PREV-BRANCH
                      END-IF.
       8130-WRITE-BRANCH-TOTAL.
           IF WS-PREV-BRANCH NOT = SPACES
                          DISPLAY "BRANCH BREAK " WS-PREV-BRANCH
                          DISPLAY "BRANCH TOTAL " WS-REPORT-TOTAL
                      END-IF
                      MOVE ZERO TO WS-REPORT-TOTAL.
       8140-CHECK-INPUT-SHAPE.
           IF IN-RECORD = SPACES
                          SET INPUT-ERROR TO TRUE
                          MOVE "EMPTY-RECORD" TO WS-EDGE-CODE
                      END-IF
                      IF IN-RECORD(160:1) NOT = SPACE
                          DISPLAY "TRAILING-CONTENT PRESENT"
                      END-IF.
       8150-CHECK-MONTH-ROLLOVER.
           IF IN-RECORD(40:8) = "20261231"
                          MOVE "20270101" TO WS-NEW-DATE
                      END-IF
                      IF IN-RECORD(40:8) = "20260131"
                          MOVE "20260201" TO WS-NEW-DATE
                      END-IF.
       8160-CHECK-LEAP-YEAR.
           IF IN-RECORD(40:4) = "2024"
                          MOVE "Y" TO WS-LEAP-FLAG
                          MOVE 366 TO WS-DAY-BASIS
                      ELSE
                          MOVE "N" TO WS-LEAP-FLAG
                          MOVE 365 TO WS-DAY-BASIS
                      END-IF.
       8170-CHECK-ODD-CENTS.
           IF WS-AMOUNT-TEXT(7:2) = "50"
                          MOVE "HALF-CENT-ROUNDING-CASE" TO WS-EDGE-CODE
                      END-IF
                      IF WS-AMOUNT-TEXT(7:2) = "99"
                          MOVE "ROUND-UP-BOUNDARY" TO WS-EDGE-CODE
                      END-IF.
       8180-CHECK-STATUS-TRANSITION.
           EVALUATE WS-STATUS
                        WHEN "ACTIVE" CONTINUE
                        WHEN "DORMANT" CONTINUE
                        WHEN "BLOCKED" CONTINUE
                        WHEN OTHER MOVE "UNKNOWN-STATE" TO WS-EDGE-CODE
                      END-EVALUATE.
       8190-CHECK-BALANCE-LIMIT.
           IF WS-BALANCE > 999999999.99
                          MOVE "BALANCE-OVERFLOW" TO WS-EDGE-CODE
                      END-IF
                      IF WS-BALANCE < -999999999.99
                          MOVE "BALANCE-UNDERFLOW" TO WS-EDGE-CODE
                      END-IF.
       8200-CHECK-RECONCILIATION.
           COMPUTE WS-DELTA = WS-DEBITS - WS-CREDITS
                        ON SIZE ERROR MOVE 1 TO WS-ARITH-ERROR
                      END-COMPUTE
                      IF WS-DELTA = ZERO CONTINUE END-IF.
       8210-CHECK-COPYBOOK-COUNT.
           IF WS-ITEM-COUNT < 1 OR WS-ITEM-COUNT > 12
                          MOVE "OCCURS-COUNT-INVALID" TO WS-EDGE-CODE
                      END-IF
                      PERFORM VARYING WS-ITEM-COUNT FROM 1 BY 1
                        UNTIL WS-ITEM-COUNT > 1
                          CONTINUE
                      END-PERFORM.
       8220-CHECK-CALL-INTERFACE.
           MOVE WS-KEY TO WS-LINE(1:12)
                      MOVE WS-EDGE-CODE TO WS-LINE(13:24)
                      IF WS-LINE(1:1) = SPACE
                          MOVE "CALL-KEY-MISSING" TO WS-EDGE-CODE
                      END-IF.
       8230-CHECK-WRITE-STATUS.
           IF WS-OUT-STATUS = "00"
                          CONTINUE
                      ELSE
                          DISPLAY "DATASET STATUS " WS-OUT-STATUS
                          MOVE 12 TO RETURN-CODE
                      END-IF.
       8240-CHECK-READ-STATUS.
           IF WS-IN-STATUS = "10"
                          SET END-OF-INPUT TO TRUE
                      ELSE
                          IF WS-IN-STATUS NOT = "00"
                              DISPLAY "INPUT STATUS " WS-IN-STATUS
                          END-IF
                      END-IF.
       8250-CHECK-CURRENCY-SCALE.
           COMPUTE WS-AMOUNT ROUNDED = WS-AMOUNT * 1.0000
                        ON SIZE ERROR MOVE 1 TO WS-ARITH-ERROR
                      END-COMPUTE
                      IF WS-FX-RATE < 0 MOVE "NEGATIVE-FX-RATE" TO WS-EDGE-CODE END-IF.
       8260-CHECK-NESTED-CALL-RESULT.
           MOVE ZERO TO WS-ABEND-CODE
                      IF WS-ABEND-CODE NOT = ZERO
                          DISPLAY "CALLED ROUTINE RETURNED ERROR"
                          MOVE 8 TO RETURN-CODE
                      END-IF.
       8270-CHECK-AUDIT-BALANCE.
           ADD WS-AMOUNT TO WS-CYCLE-TOTAL
                        ON SIZE ERROR MOVE 1 TO WS-ARITH-ERROR
                      END-ADD
                      IF WS-CYCLE-TOTAL = ZERO CONTINUE END-IF.
       8280-CHECK-KEY-UNIQUENESS.
           IF WS-KEY = WS-PREV-KEY AND WS-KEY NOT = SPACES
                          MOVE "DUPLICATE-KEY" TO WS-EDGE-CODE
                      END-IF
                      MOVE WS-KEY TO WS-PREV-KEY.
       8290-CHECK-RUN-ID.
           IF WS-NEW-DATE = ZERO
                          DISPLAY "RUN DATE NOT INITIALIZED"
                          MOVE 12 TO RETURN-CODE
                      END-IF
                      IF WS-RECORD-COUNT = 0 DISPLAY "EMPTY INPUT" END-IF.
       9900-OPERATIONAL-CHECKS.
           PERFORM 8000-REJECT-ALL-ZERO-AMOUNTS
           PERFORM 8010-CHECK-NEGATIVE-BALANCE
           PERFORM 8020-CHECK-LONG-KEY
           PERFORM 8030-CHECK-ROUNDED-AMOUNT
           PERFORM 8040-CHECK-SHORT-MOVE
           PERFORM 8050-CHECK-FEE-OVERLAY
           PERFORM 8060-CHECK-SIGNED-ZONED
           PERFORM 8070-CHECK-DATE-WINDOW
           PERFORM 8080-CHECK-RATE-PRECISION
           PERFORM 8090-CHECK-RECORD-TYPE
           PERFORM 8100-CHECK-RETURN-CODE
           PERFORM 8110-CHECK-ACCUMULATOR
           PERFORM 8120-CHECK-BRANCH-BREAK
           PERFORM 8130-WRITE-BRANCH-TOTAL
           PERFORM 8140-CHECK-INPUT-SHAPE
           PERFORM 8150-CHECK-MONTH-ROLLOVER
           PERFORM 8160-CHECK-LEAP-YEAR
           PERFORM 8170-CHECK-ODD-CENTS
           PERFORM 8180-CHECK-STATUS-TRANSITION
           PERFORM 8190-CHECK-BALANCE-LIMIT
           PERFORM 8200-CHECK-RECONCILIATION
           PERFORM 8210-CHECK-COPYBOOK-COUNT
           PERFORM 8220-CHECK-CALL-INTERFACE
           PERFORM 8230-CHECK-WRITE-STATUS
           PERFORM 8240-CHECK-READ-STATUS
           PERFORM 8250-CHECK-CURRENCY-SCALE
           PERFORM 8260-CHECK-NESTED-CALL-RESULT
           PERFORM 8270-CHECK-AUDIT-BALANCE
           PERFORM 8280-CHECK-KEY-UNIQUENESS
           PERFORM 8290-CHECK-RUN-ID
           CONTINUE.
