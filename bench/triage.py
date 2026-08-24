#!/usr/bin/env python3
"""Summarise sweep results so findings can be triaged by hand.

Zero escapes across a set of libraries is the expected answer, not a failure:
a library performs effects and its handler lives in the application. What
matters here is where the analysis went blind (unknown-effect warnings), since
that is what would hide a real finding on an application.
"""
import json, sys, glob, os, collections

def load(path):
    try:
        return json.load(open(path))
    except Exception as e:
        print(f"  ! could not read {path}: {e}")
        return None

def main(results_dir):
    files = sorted(glob.glob(os.path.join(results_dir, "*.json")))
    if not files:
        print(f"no result files in {results_dir}"); return 2
    grand = collections.Counter()
    for f in files:
        name = os.path.basename(f)[:-5]
        d = load(f)
        if d is None: continue
        s = d["summary"]
        grand.update(s)
        print(f"\n=== {name} ===")
        print(f"  total={s['total']} escapes={s['escapes']} "
              f"scheduler={s['scheduler_mismatch']} boundary={s['boundary']} "
              f"unknown={s['unknown']}")

        real = [x for x in d["findings"] if x["kind"] != "unknown"]
        if real:
            print(f"  -- {len(real)} actionable finding(s) --")
            for x in real[:10]:
                print(f"    [{x['code']}] {x['effect']}  at {x['loc']}")
                for st in x["path"][:4]:
                    print(f"         {st['loc']}  {st['what']}")
        # Where did we go blind? Cluster the unknowns by module.
        unk = [x for x in d["findings"] if x["kind"] == "unknown"]
        if unk:
            mods = collections.Counter(x["entry"].split()[0] for x in unk)
            print(f"  -- {len(unk)} unknown-effect warning(s), top modules --")
            for m, c in mods.most_common(8):
                print(f"    {c:4d}  {m}")
    print("\n=== totals ===")
    for k in ("total","escapes","scheduler_mismatch","boundary","unknown"):
        print(f"  {k:20s} {grand[k]}")
    print("""
Reading this:
  escapes = 0 on libraries is expected. Use 'unhandled contract' on a library
  to see what it asks callers to handle; 'check' is for whole programs.
  A high unknown count means calls into code with no .cmt, which is where a
  real finding could be hiding.""")
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "bench/results"))
