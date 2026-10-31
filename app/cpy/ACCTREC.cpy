      ******************************************************************
      * ACCTREC.cpy - Fictional account master record (synthetic).
      * All keys, tokens, branches: invented training data, SYN-labeled.
      * VSAM KSDS layout. Primary key ACCT-KEY (offset 1, len 12).
      * Alternate key: ACCT-CUSTOMER-TOKEN (offset 13, len 20),
      *   UPGRADE, NONUNIQUE (several accounts per customer token).
      * See app/catlg/VSAM-DEFINE.jcl for the DEFINE CLUSTER.
      ******************************************************************
       01 ACCOUNT-RECORD.
          05 ACCT-KEY              PIC X(12).
          05 ACCT-CUSTOMER-TOKEN   PIC X(20).
          05 ACCT-BRANCH-NO        PIC 9(5).
          05 ACCT-PRODUCT-CLASS    PIC X(2).
             88 ACCT-SAVINGS       VALUE "SV".
             88 ACCT-CHECKING      VALUE "CK".
             88 ACCT-LOAN-LINKED   VALUE "LN".
          05 ACCT-STATUS           PIC X.
             88 ACCT-OPEN          VALUE "A".
             88 ACCT-BLOCKED       VALUE "B".
             88 ACCT-DORMANT       VALUE "D".
             88 ACCT-CLOSED        VALUE "C".
          05 ACCT-LEDGER-BAL       PIC S9(9)V99 COMP-3.
          05 ACCT-AVAIL-BAL        PIC S9(9)V99 USAGE IS DISPLAY.
          05 ACCT-OPEN-DATE         PIC 9(8).
          05 ACCT-VARIANT-AREA     PIC X(16).
          05 ACCT-SAVINGS-VIEW REDEFINES ACCT-VARIANT-AREA.
             10 ACCT-INT-RATE      PIC 9V9999 COMP-3.
             10 FILLER             PIC X(12).
          05 ACCT-CHECKING-VIEW REDEFINES ACCT-VARIANT-AREA.
             10 ACCT-OVERDRAFT-LMT PIC S9(7)V99 COMP-3.
             10 FILLER             PIC X(9).
          05 ACCT-PRODUCT-COUNT    PIC 99.
          05 ACCT-PRODUCTS OCCURS 1 TO 12 TIMES
             DEPENDING ON ACCT-PRODUCT-COUNT.
             10 ACCT-PRODUCT-CODE  PIC X(4).
             10 ACCT-PRODUCT-AMT   PIC S9(9)V99 COMP-3.
