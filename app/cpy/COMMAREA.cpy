      ******************************************************************
      * COMMAREA.cpy - Fictional CICS-style common area (synthetic).
      * Demonstrates nested COPY plus COPY ... REPLACING:
      *   COPY PFXACCT REPLACING ==:PFX:== BY ==ACCT==.
      * expands the 10-level :PFX: fields into ACCT-KEY, ACCT-BALANCE,
      * etc. inside CA-ACCOUNT-SEGMENT. COPY DATELINK nests the date
      * linkage fragment as a following 01. All data fictional.
      ******************************************************************
       01 COMMON-AREA.
          05 CA-RETURN-CODE        PIC 9(4).
          05 CA-MESSAGE            PIC X(60).
          05 CA-ACCOUNT-SEGMENT.
             COPY PFXACCT REPLACING ==:PFX:== BY ==ACCT==.
          05 CA-ACTION             PIC X.
             88 CA-INQUIRE         VALUE "I".
             88 CA-UPDATE          VALUE "U".
       COPY DATELINK.
