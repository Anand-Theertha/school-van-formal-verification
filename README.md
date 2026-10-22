# School Van Tracking: Ordering Guarantees Under Unreliable Networks

## Abstract

We study the telemetry protocol of a real-time school-van tracking app, where a driver's phone streams GPS positions to parents over unreliable mobile networks. Using TLA+ and the TLC model checker, we model a lossy, duplicating, reordering channel and check that the position shown to a parent never moves backward. TLC found a violation in the baseline protocol, caused by a delayed frame arriving after a newer one. We added sequence-number guards at the server and the parent client and re-checked the model: no violation was found within the explored bounds (3 frames, 24 distinct states). We also tested the implementation with injected duplicate, reordered, and batched frames. We describe the gaps between the model and the deployed system and the revisions needed to close them.

## Repository Contents

This repository contains the formal verification artifacts and the accompanying technical report:

- `School_Van_Tracking-Report.pdf` — Full technical report: architecture, formal model, fault-injection tests, and future work.
- `SchoolVanTracker_Baseline.tla` — Baseline TLA+ model showing the ordering violation over an unordered, lossy network.
- `SchoolVanTracker_Guarded.tla` — Guarded TLA+ model with sequence-number checks that fix the backward-time bug.
- `SchoolVanTracker_PlusCal.tla` — PlusCal algorithmic view of the guarded protocol (driver, server/parent, and network processes).
- `SchoolVanTracker.cfg` — TLC configuration: model bounds and safety properties.

## Reproducibility

Run the models in the **TLA+ Toolbox** by evaluating **SchoolVanTracker_Guarded.tla** with `MaxSeq = 3`.

> **Note:** In TLC model properties, disable deadlock checking. The infinite read loops terminate in a waiting state, which TLC may otherwise report as deadlock.
