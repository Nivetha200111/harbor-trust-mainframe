# Harbor Trust Mainframe (fictional)

A realistic training estate for a wholly fictional retail bank. Every institution label, account key, customer token, branch, and transaction fixture is synthetic. No production names or account numbers are used. Source layout mirrors the application organization used by [aws-samples/aws-mainframe-modernization-carddemo](https://github.com/aws-samples/aws-mainframe-modernization-carddemo), with Harbor Trust specific assets.

## Layout

- `app/cbl`: 47 COBOL source modules: 25 primary estate programs plus 22 supplemental modules retained from the starter source set. The primary set contains 10 batch jobs, 6 CICS transaction programs, 3 DB2 modules, and 6 shared callable services.
- `app/cpy`: 18 copybooks, including nested `COPY`, pseudo-text `COPY ... REPLACING ==:PFX:== BY ==ACCT==`, 88-level conditions, `REDEFINES`, packed/zoned fields, and `OCCURS DEPENDING ON`.
- `app/jcl`: job stream for every batch program.
- `app/data/ascii` and `app/data/ebcdic`: five paired synthetic datasets. Accounts, transactions, checks, and loans have 1,200 records each; rates contain 1,200 rows.
- `app/bms`: BMS mapset source for inquiry, transfer, and card-control screens.
- `app/proc`: cataloged compile and batch procedures.
- `app/catlg`: VSAM KSDS/alternate-index definition and synthetic DB2 DDL.
- `app/expected`: deterministic sample control reports/reference output.

## Batch-only programs

| Program | Job purpose | JCL |
|---|---|---|
| HTIACR | Daily packed-decimal interest, rounded with size-error handling | `app/jcl/HTIACR.jcl` |
| HTNSF | Overdraft and NSF fee posting; REDEFINES waiver case | `app/jcl/HTNSF.jcl` |
| HTCHK | Cheque clearing and return reason coding | `app/jcl/HTCHK.jcl` |
| HTSTM | Month-end statement cycle and totals | `app/jcl/HTSTM.jcl` |
| HTGLR | Debit/credit reconciliation | `app/jcl/HTGLR.jcl` |
| HTDOR | Dormancy sweep and negative-balance review | `app/jcl/HTDOR.jcl` |
| HTLON | Loan amortization, compound interest, leap-year basis | `app/jcl/HTLON.jcl` |
| HTFXC | Four-decimal FX conversion | `app/jcl/HTFXC.jcl` |
| HTSRT | Ordered transaction stream / sort-merge control | `app/jcl/HTSRT.jcl` |
| HTCBR | Branch control-break activity totals | `app/jcl/HTCBR.jcl` |

## Online CICS programs

`HTAQI` account inquiry, `HTTRF` funds transfer, `HTCBL` card block, `HTTFC` transfer confirmation, `HTAHI` activity inquiry, and `HTCIN` card inquiry. The sources exercise `DFHAID`, `DFHBMSCA`, `EXEC CICS READ`, `WRITE`, `LINK`, and `XCTL`. These require a CICS region and map assembly; local GnuCOBOL alone cannot execute CICS commands.

## DB2 programs

`HTDBI` interest posting, `HTDBR` ledger reconciliation, and `HTDBS` statement retrieval use embedded SQL, cursors, host variables, `SQLCODE`/`SQLSTATE` diagnostics, and commit/rollback paths. They require DB2 precompile/bind and are not standalone GnuCOBOL jobs.

## Supplemental source modules

The starter source set also contains additional COBOL examples, listed in `app/cbl/PROGRAM-INVENTORY.md`: account inquiry/update and card search/block flows, cheque clearing, control-break and sort/merge jobs, date and dynamic-call utilities, DB2 account/statement/transaction modules, dormancy and interest accrual, FX/funds transfer, GL reconciliation, loan amortization, overdraft fees, and statement generation. These remain under `app/cbl` to preserve the complete fictional estate.

## Shared services

`HTDATE` date utility; `HTPOST` posting; `HTAUDT` audit; `HTFEEP` fee policy; `HTFXRT` rate lookup; `HTROUT` dynamic router. Calls demonstrate `USING BY REFERENCE`, `BY CONTENT`, a variable program name, static program calls, and the Language Environment `CEE3ABD` interface. Verify ABI details against the target LE release before execution.

## Edge cases represented

Half-cent rounding, negative balances, month/year rollover, 80-year YY windowing, shorter receiving PIC truncation, a fee waiver activated by a REDEFINES overlay, leap years, variable-length OCCURS groups, and arithmetic `ON SIZE ERROR` handling are explicit in source and deterministic fixtures. The sample two-digit window maps 00–80 to 2000–2080 and 81–99 to 1981–1999; production century policy must be configured deliberately.

## Running and portability

Primary batch source uses free-format COBOL with line-sequential DD names for local portability. IBM JCL, IDCAMS, BMS, CICS, and DB2 resources are reference source; adapt datasets, compiler options, and transaction definitions for a real region. The primary batch sources use free-format COBOL and compile with GnuCOBOL 3.x. For the interest job, build the callable date utility with it: `cobc -x -free -I app/cpy app/cbl/HTIACR.cbl app/cbl/HTDATE.cbl -o /tmp/HTIACR`. Set the line-sequential dataset names through the environment when running locally, for example `env 'INPUT-FILE=app/data/ascii/accounts.dat' 'OUTPUT-FILE=/tmp/interest.out' /tmp/HTIACR`. `app/expected/` contains record-level outputs and run summaries captured by compiling and executing each primary batch module with GnuCOBOL 3.x against its synthetic ASCII fixture. CICS, DB2, and IDCAMS artifacts require their respective platform tooling.

## Safety

This is fictional training material. The generated IDs are deliberately labeled `SYN`; fixture data must not be presented as data from a real institution.
