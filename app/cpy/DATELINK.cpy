      ******************************************************************
      * DATELINK.cpy - Fictional date linkage fragment (synthetic).
      * Copy into LINKAGE SECTION or after a COMMAREA 01. All dates
      * are fictional; two-digit years use the 80-year window
      * documented in the README (00-80 -> 2000-2080, else 19xx).
      ******************************************************************
       01 DATE-LINKAGE.
          05 DL-TODAY               PIC 9(8).
          05 DL-TODAY-YYYYMMDD REDEFINES DL-TODAY.
             10 DL-YEAR            PIC 9(4).
             10 DL-MONTH           PIC 99.
             10 DL-DAY             PIC 99.
          05 DL-JULIAN             PIC 9(7).
          05 DL-DAY-OF-WEEK        PIC 9.
             88 DL-WEEKDAY         VALUES 2 THRU 6.
             88 DL-WEEKEND         VALUES 1 7.
          05 DL-LEAP-FLAG          PIC X.
             88 DL-LEAP-YEAR       VALUE "Y".
             88 DL-COMMON-YEAR     VALUE "N".
