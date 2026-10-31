      ******************************************************************
      * INTPARM.cpy - Fictional interest-policy tiers (synthetic).
      ******************************************************************
       01 INTEREST-PARMS.
          05 INT-PRODUCT-CLASS     PIC X(2).
          05 INT-ROUNDING          PIC X.
             88 INT-HALF-UP        VALUE "H".
             88 INT-TRUNCATE       VALUE "T".
          05 INT-TIER-COUNT        PIC 99.
          05 INT-TIERS OCCURS 1 TO 8 TIMES
             DEPENDING ON INT-TIER-COUNT.
             10 INT-MIN-BAL        PIC S9(9)V99 COMP-3.
             10 INT-RATE           PIC 9V9999 COMP-3.
