      ******************************************************************
      * PFXACCT.cpy - Fictional prefix-parameterized account fragment
      * (synthetic). Level-10 items so this member can be nested inside
      * any group. Include with pseudo-text replacing, e.g.:
      *   COPY PFXACCT REPLACING ==:PFX:== BY ==ACCT==.
      ******************************************************************
          10 :PFX:-KEY            PIC X(12).
          10 :PFX:-CUSTOMER-TOKEN PIC X(20).
          10 :PFX:-BALANCE        PIC S9(9)V99 COMP-3.
          10 :PFX:-STATUS         PIC X.
             88 :PFX:-OPEN        VALUE "A".
             88 :PFX:-BLOCKED     VALUE "B".
             88 :PFX:-DORMANT     VALUE "D".
