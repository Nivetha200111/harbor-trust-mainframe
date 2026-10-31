      ******************************************************************
      * FEEPARM.cpy - Fictional fee-policy table (synthetic). Variable
      * fee schedule via OCCURS DEPENDING ON.
      ******************************************************************
       01 FEE-PARMS.
          05 FEE-SCHEDULE-ID       PIC X(8).
          05 FEE-COUNT             PIC 99.
          05 FEE-TABLE OCCURS 1 TO 10 TIMES
             DEPENDING ON FEE-COUNT.
             10 FEE-CODE           PIC X(4).
             10 FEE-AMOUNT         PIC S9(7)V99 COMP-3.
             10 FEE-WAIVABLE       PIC X.
                88 FEE-CAN-WAIVE   VALUE "Y".
                88 FEE-NO-WAIVE    VALUE "N".
