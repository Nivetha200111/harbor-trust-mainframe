      ******************************************************************
      * CHEQREC.cpy - Fictional cheque record (synthetic). All MICR
      * lines, routing codes, and serials are invented training data.
      ******************************************************************
       01 CHEQUE-RECORD.
          05 CHEQ-ACCOUNT          PIC X(12).
          05 CHEQ-SERIAL           PIC 9(8).
          05 CHEQ-MICR-LINE        PIC X(30).
          05 CHEQ-AMOUNT           PIC S9(9)V99 COMP-3.
          05 CHEQ-ISSUE-DATE        PIC 9(8).
          05 CHEQ-PAYEE              PIC X(30).
          05 CHEQ-RETURN-CODE      PIC X(2).
             88 CHEQ-GOOD          VALUE "00".
             88 CHEQ-NSF           VALUE "NS".
             88 CHEQ-STALE         VALUE "ST".
             88 CHEQ-STOPPED       VALUE "SP".
             88 CHEQ-ALTERED       VALUE "AL".
          05 CHEQ-CLEAR-DATE        PIC 9(8).
