      ******************************************************************
      * GLREC.cpy - Fictional general-ledger posting record (synthetic).
      * Demonstrates signed zoned (DISPLAY) beside packed (COMP-3).
      ******************************************************************
       01 GL-RECORD.
          05 GL-ACCOUNT            PIC 9(8).
          05 GL-COST-CENTER        PIC 9(5).
          05 GL-DC-FLAG            PIC X.
             88 GL-DEBIT           VALUE "D".
             88 GL-CREDIT          VALUE "C".
          05 GL-ZONED-AMOUNT       PIC S9(9)V99 USAGE IS DISPLAY.
          05 GL-PACKED-AMOUNT      PIC S9(9)V99 COMP-3.
          05 GL-POST-DATE           PIC 9(8).
          05 GL-SOURCE             PIC X(4).
          05 GL-SOURCE-TEXT REDEFINES GL-SOURCE PIC X(4).
          05 GL-JOURNAL-SEQ        PIC 9(9) COMP.
