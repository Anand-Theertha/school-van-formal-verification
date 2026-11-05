# TLC logs

Unedited TLC console output from local runs. TLC **2.20** (extension-bundled `tla2tools.jar`), **2026-10-23**.

| File | Module | Expected result |
|------|--------|-----------------|
| `baseline-monotonic-2026-10-23.txt` | `SchoolVanTracker_Baseline` | `MonotonicDisplay` violated |
| `server-guarded-monotonic-2026-10-23.txt` | `SchoolVanTracker_ServerGuarded` | violated |
| `parent-guarded-monotonic-2026-10-23.txt` | `SchoolVanTracker_ParentGuarded` | pass |
| `both-guarded-monotonic-2026-10-23.txt` | `SchoolVanTracker_Guarded` | pass |

## Commands

From the repository root:

```text
java -XX:+UseParallelGC -cp tla2tools.jar tlc2.TLC -config SchoolVanTracker_Baseline.cfg SchoolVanTracker_Baseline.tla
java -XX:+UseParallelGC -cp tla2tools.jar tlc2.TLC -config SchoolVanTracker_ServerGuarded.cfg SchoolVanTracker_ServerGuarded.tla
java -XX:+UseParallelGC -cp tla2tools.jar tlc2.TLC -config SchoolVanTracker_ParentGuarded.cfg SchoolVanTracker_ParentGuarded.tla
java -XX:+UseParallelGC -cp tla2tools.jar tlc2.TLC -config SchoolVanTracker_Guarded.cfg SchoolVanTracker_Guarded.tla
```

`baseline-monotonic-2026-10-23.txt` was captured from the VS Code extension's
run (TLC `-tool` message format, hence the `@!@!@` markers); the other three
are plain console output from the commands above. The results are identical
either way.

Use the `tla2tools.jar` from the TLA+ VS Code extension `tools/` folder or a
release from [tlaplus/tlaplus](https://github.com/tlaplus/tlaplus/releases).