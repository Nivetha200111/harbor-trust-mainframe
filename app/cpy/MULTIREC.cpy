      ******************************************************************
      * MULTIREC.cpy - Fictional multi-record-type stream layout
      * (synthetic). One 01 whose body is reinterpreted by type code
      * via REDEFINES; detail rows carry a fixed 5-entry segment
      * table plus a segment count (ODO lives in FEEPARM/INTPARM;
      * a REDEFINES branch over a fixed area may not be variable).
      ******************************************************************
       01 MULTI-RECORD.
          05 MR-TYPE-CODE          PIC X.
             88 MR-HEADER          VALUE "H".
             88 MR-DETAIL          VALUE "D".
             88 MR-TRAILER         VALUE "T".
          05 MR-BODY               PIC X(120).
          05 MR-HEADER-REC REDEFINES MR-BODY.
             10 MR-H-FILE-DATE     PIC 9(8).
             10 MR-H-SOURCE        PIC X(8).
             10 FILLER             PIC X(104).
          05 MR-DETAIL-REC REDEFINES MR-BODY.
             10 MR-D-ACCOUNT       PIC X(12).
             10 MR-D-AMOUNT        PIC S9(9)V99 COMP-3.
             10 MR-D-SEG-COUNT     PIC 99.
             10 MR-D-SEGS OCCURS 5 TIMES.
                15 MR-D-SEG-CODE   PIC X(4).
                15 MR-D-SEG-AMT    PIC S9(9)V99 COMP-3.
          05 MR-TRAILER-REC REDEFINES MR-BODY.
             10 MR-T-REC-COUNT     PIC 9(9) COMP.
             10 MR-T-HASH-TOTAL    PIC S9(11)V99 COMP-3.
             10 FILLER             PIC X(103).
