      ******************************************************************
      * FXRATES.cpy - Fictional FX rate table (synthetic training data).
      * Base currency is the fictional SYN dollar; every rate invented.
      ******************************************************************
       01 FX-RATE-TABLE.
          05 FX-BASE-CURR          PIC X(3) VALUE "SYN".
          05 FX-RATE-DATE           PIC 9(8).
          05 FX-RATE-COUNT         PIC 99.
          05 FX-RATES OCCURS 1 TO 20 TIMES
             DEPENDING ON FX-RATE-COUNT.
             10 FX-CURR-CODE       PIC X(3).
             10 FX-BUY-RATE        PIC 9(5)V9999 COMP-3.
             10 FX-SELL-RATE       PIC 9(5)V9999 COMP-3.
             10 FX-DECIMALS        PIC 9.
