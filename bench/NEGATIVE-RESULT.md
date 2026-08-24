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
- Or pick corpus entries whose bug is in a module with few system dependencies,
  filtering candidates by whether the touched files build in isolation.

Neither is a change to the analyser. Both are changes to the corpus, and the
first honest thing to report is that we could not build the code the bugs live
in.
