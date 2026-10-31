      ******************************************************************
      * LOANREC.cpy - Fictional loan master record (synthetic).
      * All loan IDs, rates, balances: invented training data.
      ******************************************************************
       01 LOAN-RECORD.
          05 LOAN-ID               PIC X(12).
          05 LOAN-ACCOUNT          PIC X(12).
          05 LOAN-STATUS           PIC X.
             88 LOAN-CURRENT       VALUE "A".
             88 LOAN-PAST-DUE      VALUE "P".
             88 LOAN-PAID-OFF      VALUE "C".
          05 LOAN-PRINCIPAL        PIC S9(9)V99 COMP-3.
          05 LOAN-RATE             PIC 9V9999 COMP-3.
          05 LOAN-TERM-MONTHS      PIC 999.
          05 LOAN-START-DATE        PIC 9(8).
          05 LOAN-SCHEDULE OCCURS 1 TO 360 TIMES
             DEPENDING ON LOAN-TERM-MONTHS.
             10 LOAN-DUE-DATE      PIC 9(8).
             10 LOAN-DUE-AMT       PIC S9(9)V99 COMP-3.
             10 LOAN-PAID-FLAG     PIC X.
                88 LOAN-PAID       VALUE "Y".
                88 LOAN-UNPAID     VALUE "N".
