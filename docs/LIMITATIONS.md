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

## Imprecise (may report false positives)

- **Conditionals.** Both arms are joined, so an effect performed only on a path
  that never executes is still reported. Measured at 5.3% of 400 generated
  branching programs; see the table in the README.

- Calls to functions with no `.cmt` available become `Top`, reported as a
  warning about unknown effects rather than a specific escape.
- `effc` arms whose right-hand side is not a literal `Some`/`None` are treated
  as not handled.
- Library mode (`unhandled contract`) reports effect contracts rather than
  errors, so libraries no longer look broken. Errors remain reserved for whole
  programs and for scheduler mismatches.

- The scheduler table in `models/schedulers.conf` carries the real entry-point
  paths for Eio, Riot, Moonpool and Miou, but those have not yet been confirmed
  against installed sources. The detection mechanism is independent of the
  data, and the mock schedulers in `test/schedulers` exercise it.

## Not yet implemented

- Boundary-crossing effects (B3): signal handlers, finalisers, GC alarms, and
  effects crossing C `caml_callback` frames.
- 0-CFA for function values that flow through variables and data structures.
- LSP server.
