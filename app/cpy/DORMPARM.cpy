      ******************************************************************
      * DORMPARM.cpy - Fictional dormancy-sweep parameters (synthetic).
      ******************************************************************
       01 DORMANCY-PARMS.
          05 DORM-INACTIVE-DAYS    PIC 9(5).
          05 DORM-MIN-BAL-REVIEW   PIC S9(9)V99 COMP-3.
          05 DORM-NEG-REVIEW-FLAG PIC X.
             88 DORM-REVIEW-NEG    VALUE "Y".
             88 DORM-SKIP-NEG      VALUE "N".
          05 DORM-ESCHEAT-DAYS    PIC 9(5).
