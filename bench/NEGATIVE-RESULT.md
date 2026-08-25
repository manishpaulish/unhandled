# Why the retroactive catch rate is 0 of 6

Three rounds of fixes did not move this number. Each round found a real defect
in the analyser, and none of them was the reason. The honest account is more
useful than the number would have been, so it is recorded here in full.

## The measurement

Six commits from `jeong-sik/masc` that fixed documented `Effect.Unhandled`
problems. For each, the parent commit is analysed: that is where the bug still
existed. All six parents **built successfully** — this is not build attrition.

    caught 0, not caught 6, build failed 0

## Four layers, peeled in order

**1. The domain discarded what it knew.** `Effect_set` was
`Known of set | Top`, so one unresolved call anywhere in a module initialiser
collapsed the whole set and hid every effect we *had* identified. Fixed:
`{ known; unknown }`. The sweep number changed; the retro number did not.

**2. Blind spots in the call graph.** Alcotest accounted for ~79 of 107
unknown-effect warnings, so every test executable was opaque, and test code is
where these crashes live. Module aliases (`module D = Foo`) resolved to
nothing, hiding a whole class of cross-module calls. Both fixed; blindness on
masc fell 48 → 39 → 20. The retro number did not move.

**3. The wrong model of scope.** The commits read *"wrap tests in Eio
context"*, *"Eio work runs on a bare systhread"*, *"guard Domain_pool_ref
submits against non-Eio callers"*. None is a handler missing from the call
graph; each is a **dynamic context transfer**. `Domain.spawn` was even modelled
as a combinator, attributing spawned effects to the caller — the opposite of
the truth. Fixed as a boundary class, runtime-verified in `test/transfer`. The
retro number did not move.

**4. No effect model for the dependency.** Eio is installed, so it has no
`.cmt` files: `Eio.Mutex.use_rw` was an anonymous unresolved call carrying no
named effect, and nothing could be reported about it. `api`/`requires` lines
fixed that, verified in `test/eio_api` and `test/eio_ok`. The retro number
**still** did not move.

## The actual reason

The builds are `partial`. Across every run — sweep and retro, before and after
each fix — the blindness rankings contain `Unix`, `Alcotest`, `Ptime`,
`Ppxlib`, `Selection`, `Toml_line_editor`, `Fpath`. **They never contain a
single `Eio.` call.**

Confirmed directly:

```
$ find bench/_retro/masc/_build -name '*.cmt' | grep -ci eio
0
```

Not one module with `eio` in its name was compiled, across the whole retro
build tree. masc's Eio-dependent modules do not compile in our environment. What was
analysed is the periphery: TUI selection logic, a TOML line editor,
code-address parsing, ppx tests. The corpus never contained the buggy code, so
no model could have caught these bugs.

This makes the result **verified rather than inferred**. Three earlier
explanations were plausible and wrong; this one is checkable in one command,
and the check was run.

## Two claims that needed evidence, not argument

The account above still leaned on two things we had asserted. Both are now
measured.

**Claim A: the fixed files were never compiled.** The grep shows no Eio module
built, but it does not show, commit by commit, whether *the file the fix
touched* was among the ones we analysed. `retro_batch.sh` now takes the file
list from each fixing commit and checks each against the build tree, so every
row reports one of three outcomes rather than two:

| outcome | meaning |
|---|---|
| `CAUGHT` | a real finding at the parent commit |
| `MISS` | the fixed file compiled and we said nothing — a result about the detector |
| `out of scope` | the fixed file never compiled — a result about the corpus |

A catch rate is then reported over the scoped rows only, and if no fixed file
ever compiled the script says the rate is undefined instead of printing zero.
**0 of 6 and 0 of 0 are different claims**, and the first batch could not tell
them apart.

**Claim B: the detector would have fired.** "The corpus never contained the
buggy code" implies we would have caught it if it had, which is exactly the
kind of thing a losing analyser also says. `test/eio_nocmt` settles it: a
helper calling `Eio.Mutex.use_rw` with no runtime above it, with the Eio
`.cmt` files **deleted before the check**, reproducing the condition every
real run works under. The module is named `Eio__Mutex` so the path mangling
matches a wrapped dune library.

```
masc shape, Eio has no .cmt              PASS
```

It fires, and it stays quiet on the same call under `Eio_main.run`. Deleting
the `api` lines from the scheduler model makes both scenarios fail, so the
test has teeth rather than passing by accident.

So the honest statement is now: *the detector fires on this bug class under
the conditions of the failed run; the run did not present the bug to it.*
That is a much narrower claim than the one we were making, and unlike the
earlier version it is demonstrable in a terminal.

## What this is worth saying

Layers 1 to 4 were all genuine defects, and each was found only by contact with
real code — the 1000-program fuzzer found none of them, because generated
programs call nothing the analyser cannot see. That is the transferable lesson:
**a synthetic corpus validates the algorithm; only real code validates the
model.**

Layer 5 is a different kind of limitation and belongs in any honest evaluation
of a whole-program analyser: it needs the whole program. Analysing a large
application requires building it, and large applications with system
dependencies frequently will not build in a clean environment. The tool is not
wrong here; its evaluation is bounded by what the ecosystem lets us compile.

## What would change the answer

- Reproduce a fixing commit in an environment where the Eio-dependent modules
  actually compile, most likely with the project's own CI container.
- Pick corpus entries whose bug is in a module with few system dependencies.
  The coverage column now makes this a filter rather than a guess: run the
  batch, keep the commits that report `MISS` or `CAUGHT`, discard the ones
  that report `out of scope`, and the surviving denominator is real.
- Widen the corpus. `bench/discover.sh` derives it from opam — every published
  package depending on `eio`, `picos`, `domainslib`, `riot`, `moonpool` or
  `miou`, resolved to its `dev-repo` and deduplicated. A rate measured over a
  hand-written list is a rate over one person's recall; this one is
  reproducible and its attrition is counted.

None of these is a change to the analyser. All are changes to the corpus, and
the first honest thing to report is still that we could not build the code the
bugs live in.
