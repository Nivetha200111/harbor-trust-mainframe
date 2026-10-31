      ******************************************************************
      * TRANREC.cpy - Fictional transaction record (synthetic).
      * All IDs and amounts: invented training data. VSAM KSDS layout.
      * Primary key TRAN-ID (offset 1, len 12). Alternate key:
      * TRAN-ACCOUNT (offset 13, len 12), UPGRADE, NONUNIQUE.
      ******************************************************************
       01 TRANSACTION-RECORD.
          05 TRAN-ID               PIC X(12).
          05 TRAN-ACCOUNT          PIC X(12).
          05 TRAN-TYPE             PIC X.
             88 TRAN-POSTING       VALUE "P".
             88 TRAN-REVERSAL      VALUE "R".
             88 TRAN-FEE           VALUE "F".
             88 TRAN-ADJUSTMENT    VALUE "A".
          05 TRAN-CHANNEL          PIC X(4).
          05 TRAN-CHANNEL-TEXT REDEFINES TRAN-CHANNEL PIC X(4).
          05 TRAN-AMOUNT           PIC S9(9)V99 COMP-3.
          05 TRAN-POST-DATE         PIC 9(8).
          05 TRAN-VALUE-DATE        PIC 9(8).
          05 TRAN-DESC              PIC X(30).
          05 TRAN-REV-INFO REDEFINES TRAN-DESC.
             10 TRAN-ORIG-ID       PIC X(12).
             10 TRAN-REASON        PIC X(2).
                88 TRAN-DUP        VALUE "DU".
                88 TRAN-NSF        VALUE "NS".
                88 TRAN-FRAUD-HOLD VALUE "FH".
             10 FILLER             PIC X(16).
