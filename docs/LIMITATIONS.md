# Limitations

Stated plainly, because a checker that hides its blind spots is worse than one
that reports them.

## Unsound (may miss real bugs)

- **Handler bodies.** Effects performed *inside* an `effc` branch body (the
  `Some (fun k -> ...)` part) are not yet attributed. They are not discharged by
  the handler that contains them.
- **Dynamically built handler records.** If `effc` is not a literal function at
  the installation site, we cannot see which effects it handles.
- **Function values through data.** A closure stored in a record or list and
  called later is not resolved until 0-CFA lands (tier 3).
- **`Obj.magic`, C stubs, first-class modules.** Out of scope.

## Modelling assumptions about third-party libraries

`Unix`, `Str`, `Ptime`, `Yojson`, `Re`, `Fmt`, `Astring`, `Uutf` and `Sexplib0`
are treated as performing no user-defined effects: they transform data or wrap
syscalls and do not call back into caller-supplied code. `Alcotest.test_case` is
modelled as a higher-order combinator, since it takes the test body.

These came from measurement rather than guesswork. On the sweep, Alcotest
accounted for about 79 of 107 unknown-effect warnings and `Unix` for most of
the remainder. A wrong entry here hides bugs rather than merely adding noise,
so the list is deliberately short and every addition is justified by the
blindness ranking in `bench/`.

## Deliberate suppressions

- `try ... with Effect.Unhandled _` is treated as discharging the body's
  effects. The effect genuinely escapes there, but the author has handled the
  consequence on purpose; one real codebase does this in over fifty places.
  Reporting them would be defensible and useless.

## Imprecise (may report false positives)

- **Conditionals.** Both arms are joined, so an effect performed only on a path
  that never executes is still reported. Measured at 5.3% of 400 generated
  branching programs; see the table in the README.

- Calls to functions with no `.cmt` available become `Top`, reported as a
  warning about unknown effects rather than a specific escape.
- **Modelling assumption:** the standard library performs no *user-defined*
  effects, so an unmodelled `Stdlib.*` call is treated as pure. Without this,
  every call to `Printf` or `Gc` degrades the result to "unknown". `Effect`,
  `Lazy` and `Domain` are excluded, since they can run caller-supplied code.
- `effc` arms whose right-hand side is not a literal `Some`/`None` are treated
  as not handled.
- Library mode (`unhandled contract`) reports effect contracts rather than
  errors, so libraries no longer look broken. Errors remain reserved for whole
  programs and for scheduler mismatches.

- The scheduler table in `models/schedulers.conf` carries the real entry-point
  paths for Eio, Riot, Moonpool and Miou, but those have not yet been confirmed
  against installed sources. The detection mechanism is independent of the
  data, and the mock schedulers in `test/schedulers` exercise it.

## Resource use on very large trees

`check` holds every module's summary in memory at once. On the opam-derived
sweep this was fine for 2093 modules (`awso-eio`) but the process was
SIGKILLed by the OS on one repository, `dns-client-miou-unix`:

```
bench/sweep.sh: line 54: 14402 Killed: 9   "$UNHANDLED" check .../_build --json
```

That is our process dying, not the analysis being wrong, and it is a real
limit rather than a hypothetical one. The sweep records it as attrition. Not
yet diagnosed: whether it is total footprint or a pathological case in the
fixpoint. Anyone reproducing our numbers should expect it.

## Not yet implemented

- 0-CFA for function values that flow through variables and data structures.
- LSP server.
- B3 covers the registration sites we model (`Gc.finalise`, `Gc.finalise_last`,
  `Gc.create_alarm`, `Sys.signal`, `Sys.set_signal`, `Callback.register`,
  `Gc.Memprof.start`). A callback reaching a fatal context by some other route
  is not detected.
