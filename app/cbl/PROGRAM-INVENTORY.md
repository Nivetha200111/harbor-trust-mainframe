# Program inventory

| Program | Role | Execution class |
|---|---|---|
| HTIACR | Daily interest accrual | Batch-only |
| HTNSF | Overdraft and NSF fee posting | Batch-only |
| HTCHK | Cheque clearing and returns | Batch-only |
| HTSTM | End-of-month statement generation | Batch-only |
| HTGLR | General-ledger reconciliation | Batch-only |
| HTDOR | Dormant-account sweep | Batch-only |
| HTLON | Loan amortisation with compound interest and leap-year accrual | Batch-only |
| HTFXC | FX conversion using four-decimal rates | Batch-only |
| HTSRT | Sort and merge transaction stream | Batch-only |
| HTCBR | Control-break activity report | Batch-only |
| HTAQI | Account inquiry | CICS |
| HTTRF | Funds transfer | CICS |
| HTCBL | Card block | CICS |
| HTTFC | Transfer confirmation | CICS |
| HTAHI | Account activity inquiry | CICS |
| HTCIN | Card inquiry | CICS |
| HTDBI | Interest posting | DB2 |
| HTDBR | GL reconciliation | DB2 |
| HTDBS | Statement retrieval | DB2 |
| HTDATE | Date normalization utility | Shared callable |
| HTPOST | Shared ledger posting service | Shared callable |
| HTAUDT | Audit trail writer | Shared callable |
| HTFEEP | Fee waiver policy | Shared callable |
| HTFXRT | FX rate lookup service | Shared callable |
| HTROUT | Dynamic transaction router | Shared callable |

## Supplemental source modules

| Program | Role | Execution class |
|---|---|---|
| HTACINQ | Account inquiry | CICS supplemental |
| HTACUPD | Account update | CICS supplemental |
| HTCARDBK | Card block support | CICS supplemental |
| HTCHQCLR | Cheque clearing | Batch supplemental |
| HTCTRLBR | Control-break report | Batch supplemental |
| HTCSRCH | Customer/account search | CICS supplemental |
| HTDATEUT | Date utility | Batch supplemental |
| HTDBACCT | Account master cursor read | DB2 supplemental |
| HTDBDEF | DB2 host and table definitions | DB2 supplemental |
| HTDBSTMT | Statement query | DB2 supplemental |
| HTDBTRAN | Transaction query | DB2 supplemental |
| HTDORMSW | Dormancy sweep support | Batch supplemental |
| HTDYNAC | Dynamic account call | Batch supplemental |
| HTFXCONV | FX conversion support | Batch supplemental |
| HTGLRECO | GL reconciliation support | Batch supplemental |
| HTINTACC | Interest accrual support | Batch supplemental |
| HTLOANAM | Loan amortization support | Batch supplemental |
| HTOVDFEE | Overdraft fee support | Batch supplemental |
| HTPINCH | PIN change flow | CICS supplemental |
| HTSORTMG | Sort/merge support | Batch supplemental |
| HTSTMTM | Statement generation support | Batch supplemental |
| HTXFUND | Funds transfer support | CICS supplemental |
