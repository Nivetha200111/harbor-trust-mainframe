      ******************************************************************
      * STMTPARM.cpy - Fictional statement-cycle parameters (synthetic).
      ******************************************************************
       01 STATEMENT-PARMS.
          05 STMT-CYCLE-MONTH       PIC 9(6).
          05 STMT-CUTOFF-DATE       PIC 9(8).
          05 STMT-MIN-BAL-PRINT    PIC S9(9)V99 COMP-3.
          05 STMT-PAGE-SIZE        PIC 99.
          05 STMT-FLAG             PIC X.
             88 STMT-RUN-ALL       VALUE "A".
             88 STMT-RUN-DELTA     VALUE "D".
