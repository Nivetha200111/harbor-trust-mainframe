#!/usr/bin/env python3
"""Regenerate deterministic, explicitly synthetic Harbor Trust fixtures."""
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def account_record(i: int, kind: str) -> str:
    key = f"SYN{i:09d}"
    branch = "BR" + chr(65 + i % 26)
    amount = f"{(i * 7919) % 99_999_999:08d}"
    status = ["ACTIVE", "DORMANT", "BLOCKED"][i % 3].ljust(8)
    token = f"TOK{i % 999_999:06d}".ljust(8)
    date = ["20261231", "20260228", "20240131", "20251130"][i % 4]
    record = kind + key[1:] + branch + amount + status + token + date
    return record.ljust(119) + ("Y" if i % 89 == 0 else "N") + " " * 40

def write_pair(name: str, rows: list[str]) -> None:
    text = "\n".join(rows) + "\n"
    (ROOT / "app/data/ascii" / name).write_text(text, encoding="ascii")
    ebcdic = subprocess.run(
        ["iconv", "-f", "ASCII", "-t", "CP037"],
        input=text.replace("\n", "").encode("ascii"),
        stdout=subprocess.PIPE,
        check=True,
    ).stdout
    (ROOT / "app/data/ebcdic" / (Path(name).stem + ".ebc")).write_bytes(ebcdic)

for filename, kind in {
    "accounts.dat": "A",
    "transactions.dat": "T",
    "checks.dat": "C",
    "loans.dat": "L",
}.items():
    write_pair(filename, [account_record(i, kind) for i in range(1, 1201)])

rates = []
for currency, rate in [("EUR", ".9234"), ("GBP", ".7912"), ("JPY", "149.2500")]:
    scaled = {".9234": "00009234", ".7912": "00007912", "149.2500": "01492500"}[rate]
    rates.extend((f"AYN{i:09d}BRA{scaled}ACTIVE  USD{currency}{rate:>8}20260101".ljust(160)) for i in range(1, 401))
write_pair("fx-rates.dat", rates)
