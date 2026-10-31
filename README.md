# Harbor Trust Mainframe (fictional)

A realistic training estate for a wholly fictional retail bank. Every institution label, account key, customer token, branch, and transaction fixture is synthetic. No production names or account numbers are used. Source layout mirrors the application organization used by [aws-samples/aws-mainframe-modernization-carddemo](https://github.com/aws-samples/aws-mainframe-modernization-carddemo), with Harbor Trust specific assets.

## Layout

- `app/cbl`: 47 COBOL source modules: 25 primary estate programs plus 22 supplemental modules retained from the starter source set. The primary set contains 10 batch jobs, 6 CICS transaction programs, 3 DB2 modules, and 6 shared callable services.
- `app/cpy`: 35 copybooks, including nested `COPY`, pseudo-text `COPY ... REPLACING ==:PFX:== BY ==ACCT==`, 88-level conditions, `REDEFINES`, packed/zoned fields, and `OCCURS DEPENDING ON`.
- `app/jcl`: 27 members, one job stream for every batch program (10 primary, 11 extended batch, 6 DB2 batch via `IKJEFT01`).
- `app/data/ascii` and `app/data/ebcdic`: five paired synthetic datasets. Accounts, transactions, checks, and loans have 1,200 records each; rates contain 1,200 rows. `scripts/generate-fixtures.py` regenerates the ASCII fixtures byte-identically; the EBCDIC variants are CP037 transcodes with line separators omitted.
- `app/bms`: BMS mapset source for inquiry, transfer, and card-control screens (7 mapsets).
- `app/proc`: cataloged compile (`HTCOBOL`) and batch (`HTBATCH`) procedures.
- `app/catlg`: VSAM KSDS/alternate-index definition and synthetic DB2 DDL.
- `app/expected`: 21 deterministic reference outputs (record lines plus run summary) captured from GnuCOBOL 3.x runs against the synthetic fixtures.
- `scripts/generate-fixtures.py`: deterministic fixture generator; verified byte-identical against the checked-in fixtures.

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

## Extended batch programs

| Program | Job purpose | Fixture | JCL |
|---|---|---|---|
| HTINTACC | Daily interest accrual, half-cent trap | `accounts.dat` | `app/jcl/HTINTACC.jcl` |
| HTOVDFEE | Overdraft/NSF posting, negative-balance trap | `transactions.dat` | `app/jcl/HTOVDFEE.jcl` |
| HTDORMSW | Dormant sweep past 365-day threshold | `accounts.dat` | `app/jcl/HTDORMSW.jcl` |
| HTLOANAM | Amortisation, leap-year logic, pivot-80 windowing | `loans.dat` | `app/jcl/HTLOANAM.jcl` |
| HTFXCONV | FX conversion, 4-decimal COMP-3 rates | `fx-rates.dat` | `app/jcl/HTFXCONV.jcl` |
| HTCHQCLR | Cheque clearing, R01-R09 return codes | `checks.dat` | `app/jcl/HTCHQCLR.jcl` |
| HTSTMTM | Statement cycle, month/year-end rollover | `transactions.dat` | `app/jcl/HTSTMTM.jcl` |
| HTGLRECO | Subledger vs GL reconciliation with suspense | `transactions.dat` | `app/jcl/HTGLRECO.jcl` |
| HTSORTMG | SORT/MERGE verb job (DFSORT pre-sort step in JCL) | `transactions.dat` | `app/jcl/HTSORTMG.jcl` |
| HTCTRLBR | Branch/account control breaks, page breaks | `transactions.dat` | `app/jcl/HTCTRLBR.jcl` |
| HTDYNAC | Dynamic CALL demo plus `CEE3ABD` path | `transactions.dat` | `app/jcl/HTDYNAC.jcl` |

`HTDATEUT` is a called date subprogram (no JCL); the six fixed-format template jobs resolve it by static link. The interest/fee/dormancy/loan/FX programs compile with `cobc -free -I app/cpy`; the six template jobs compile with `cobc -fixed -I app/cpy`. Template jobs write an audit trail, so their JCL includes an `AUDIT-FILE` DD.

## Execution-class matrix

| Class | Programs | Runs under GnuCOBOL 3.x | Needs |
|---|---|---|---|
| Batch-only (primary) | HTIACR, HTNSF, HTCHK, HTSTM, HTGLR, HTDOR, HTLON, HTFXC, HTSRT, HTCBR | Yes, reference output in `app/expected/` | Line-sequential fixtures via `INPUT-FILE`/`OUTPUT-FILE` |
| Batch-only (extended) | HTINTACC, HTOVDFEE, HTDORMSW, HTLOANAM, HTFXCONV, HTCHQCLR, HTSTMTM, HTGLRECO, HTSORTMG, HTCTRLBR, HTDYNAC | Yes, reference output in `app/expected/` | As above, plus audit DD for the six fixed-format jobs |
| DB2 batch | HTDBI, HTDBR, HTDBS, HTDBACCT, HTDBTRAN, HTDBSTMT | No (`EXEC SQL` needs precompile) | DB2 BIND + `IKJEFT01` RUN; see `app/jcl/HTDB*.jcl` |
| Online CICS | HTAQI, HTTRF, HTCBL, HTTFC, HTAHI, HTCIN (+ supplemental HTACINQ, HTACUPD, HTCSRCH, HTCARDBK, HTPINCH, HTXFUND) | No (`EXEC CICS`, `DFHAID` need a translator/region) | CICS region, map assembly from `app/bms` |
| Called services | HTDATE, HTPOST, HTAUDT, HTFEEP, HTFXRT, HTROUT, HTDATEUT | As subprograms only (`PROCEDURE DIVISION USING`) | Statically linked into the calling batch executable |
| DDL placeholder | HTDBDEF | N/A (documents fictional tables only) | None |

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

## Build verification (GnuCOBOL 3.2.0)

All 21 batch programs compile clean and run to completion against the synthetic fixtures: the 10 primary jobs accept 1,200/1,200 records each with output identical to the checked-in `app/expected/` references, and the 11 extended jobs accept 1,200/1,200 with fresh references captured in `app/expected/` (re-runs are byte-stable). Service modules (`HTDATE`, `HTPOST`, `HTAUDT`, `HTFEEP`, `HTFXRT`) and `HTDATEUT` are statically linked into their callers. `HTOVDFEE` ends RC=8 by design after exercising its `ON SIZE ERROR` path; all others end RC=0. CICS sources fail at the translator stage (`DFHAID` has no GnuCOBOL copybook) and DB2 sources need precompile, exactly as the matrix above records.

Portability fixes applied during integration (behavior-preserving, estate-consistent): `WS-AMOUNT-TEXT` narrowed from `X(12)` to the estate-standard `X(8)` in the 11 extended sources (only 8 bytes are ever moved in; the wider field left trailing spaces that tripped the `IS NUMERIC` check); `STRING` of a `COMP-5` counter routed through a `DISPLAY` field in the six template jobs; missing `SELECT` entries added for the `SORT-WORK`/`MERGE-WORK` sort files; `HTDATEUT` callee-side `BY CONTENT` corrected to `BY REFERENCE` (matching how every `CALL ... BY CONTENT` site already passes its argument).

## Safety

This is fictional training material. The generated IDs are deliberately labeled `SYN`; fixture data must not be presented as data from a real institution.
