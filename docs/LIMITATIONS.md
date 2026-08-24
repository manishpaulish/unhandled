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

- Calls to functions with no `.cmt` available become `Top`, reported as a
  warning about unknown effects rather than a specific escape.
- `effc` arms whose right-hand side is not a literal `Some`/`None` are treated
  as not handled.
- Library code analysed on its own will appear to leak effects: its handlers
  live in the application. Library mode (reporting effect *contracts* rather
  than errors) is planned; until then analyse whole programs.

## Not yet implemented

- Scheduler-mismatch detection (B2) and boundary-crossing effects (B3).
- Witness generation.
- LSP server.
