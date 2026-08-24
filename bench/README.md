# Ecosystem sweep

Runs `unhandled` across real OCaml 5 projects and produces `results/sweep.csv`.

```
dune build
bash bench/sweep.sh                 # everything in repos.txt
REPOS="eio picos" bash bench/sweep.sh
```

Needs `opam` and a 5.x switch. **This cannot run in a sandbox without opam
access**, which is why the harness is committed separately from its results.

Every repo is recorded, including the ones that fail to clone or build. That
attrition is part of the result: "12 of 13 repos analysed" is an honest
denominator, and silently dropping the failures would inflate every rate
computed from this table.

`sweep.csv` columns: repo, status, modules, findings, escapes, unknown,
scheduler_mismatch, boundary, seconds.

Statuses: `ok`, `clone_failed`, `build_failed`, `no_cmt`.

## After a sweep

1. Triage `results/*.json`. Each finding carries a blame path.
2. For anything that looks real, run `unhandled witness` to try to get an
   executable proof before reporting it upstream.
3. Record confirmed defects and false positives in `results/triage.md` with a
   reason for each, so the precision number in the report is reproducible.
