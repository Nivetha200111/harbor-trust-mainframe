      ******************************************************************
      * SQLDIAG.cpy - Fictional SQLCA-style diagnostic / host-var area
      * (synthetic). Mirrors the shape of an SQLCA for training only;
      * it is not a vendor copybook. All values synthetic.
      ******************************************************************
       01 SYN-SQL-DIAG-AREA.
          05 SYN-SQLCODE           PIC S9(9) COMP.
             88 SYN-SQL-OK         VALUE 0.
             88 SYN-SQL-NOT-FOUND  VALUE 100.
          05 SYN-SQLSTATE          PIC X(5).
          05 SYN-SQLERRM-LEN       PIC 9(4) COMP.
          05 SYN-SQLERRM-TEXT      PIC X(70).
          05 SYN-HOST-NULL-IND     PIC S9(4) COMP.
             88 SYN-HOST-NULL      VALUE -1.
             88 SYN-HOST-NOT-NULL  VALUE 0.
