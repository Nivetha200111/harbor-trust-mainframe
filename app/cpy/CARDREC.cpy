      ******************************************************************
      * CARDREC.cpy - Fictional card record (synthetic). All PANs,
      * tokens, and limits are invented training values (SYN-labeled).
      ******************************************************************
       01 CARD-RECORD.
          05 CARD-NUMBER-TOKEN     PIC X(20).
          05 CARD-ACCOUNT          PIC X(12).
          05 CARD-HOLDER-SEQ       PIC 99.
          05 CARD-STATUS           PIC X.
             88 CARD-ACTIVE        VALUE "A".
             88 CARD-BLOCKED       VALUE "B".
             88 CARD-LOST          VALUE "L".
             88 CARD-STOLEN        VALUE "S".
             88 CARD-EXPIRED       VALUE "E".
          05 CARD-EXPIRY-YYYYMM     PIC 9(6).
          05 CARD-DAILY-LIMIT      PIC S9(9)V99 COMP-3.
          05 CARD-DAILY-USED       PIC S9(9)V99 COMP-3.
