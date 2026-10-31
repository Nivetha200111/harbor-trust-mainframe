#!/usr/bin/env python3
"""Regenerate the fictional Harbor Trust synthetic fixtures.

All output is deterministic fiction: synthetic keys, branch codes,
amounts, dates and tokens. No real names, accounts or institutions.
Regenerates app/data/ascii/*.dat byte-identically; use
`iconv -f UTF-8 -t CP037` to reproduce the app/data/ebcdic counterparts
(fixed width preserved, line separators omitted).
"""

import os

HERE = os.path.dirname(os.path.abspath(__file__))
ASCII = os.environ.get(
    "FIXTURE_DIR",
    os.path.normpath(os.path.join(HERE, "..", "app", "data", "ascii")),
)

DATES = ["20260228", "20240131", "20251130", "20261231"]
STATUSES = ["DORMANT ", "BLOCKED ", "ACTIVE  "]


def ledger_row(prefix, i):
    seq = i + 1
    branch = "BR" + chr(ord("A") + (seq % 26))
    amount = "%08d" % (7919 * seq)
    status = STATUSES[i % 3]
    date = DATES[i % 4]
    flag = "Y" if seq >= 89 and (seq - 89) % 89 == 0 else "N"
    row = ("%-1sYN%09d%-3s%-8s%-8s%-3s%06d%-8s"
           % (prefix, seq, branch, amount, status, "TOK", seq, date))
    return row.ljust(119) + flag + " " * 40


FX_BLOCKS = [
    ("USDEUR", "00009234", "   .9234"),
    ("USDGBP", "00007912", "   .7912"),
    ("USDJPY", "01492500", "149.2500"),
]


def fx_row(j, pair, amount, rate8):
    seq = j + 1
    row = ("AYN%09dBRA%-8s%-8s%-6s%-8s%-8s"
           % (seq, amount, "ACTIVE  ", pair, rate8, "20260101"))
    return row.ljust(160)


def main():
    os.makedirs(ASCII, exist_ok=True)
    for name, prefix in [("accounts", "A"), ("transactions", "T"),
                         ("checks", "C"), ("loans", "L")]:
        with open(os.path.join(ASCII, name + ".dat"), "w") as fh:
            for i in range(1200):
                fh.write(ledger_row(prefix, i) + "\n")
    with open(os.path.join(ASCII, "fx-rates.dat"), "w") as fh:
        for pair, amount, rate8 in FX_BLOCKS:
            for j in range(400):
                fh.write(fx_row(j, pair, amount, rate8) + "\n")
    print("wrote 5 fixtures to", ASCII)


if __name__ == "__main__":
    main()
