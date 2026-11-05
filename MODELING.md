# Modeling notes

This document records what the TLA+ specs claim, TLC results, and deployment
mapping.

## What TLC can show

A TLC counterexample shows that **this abstract protocol**, under **these
channel assumptions**, can violate (or satisfy) a property. It does not prove
anything about real cellular networks or production code by itself.

## Channel structure

- **Driver → server:** `network_buffer` (unordered, lossy via `NetworkDrop`).
- **Server → parent:** `parent_channel` (unordered; separate from the uplink).

**Production mapping:** Redis pub/sub on the downlink may preserve order from a
single publisher. The model uses an **unordered** downlink because **multiple
nodes** can publish toward parents, so deliveries need not match send order.
The model itself has a single server with one shared `server_ack_seq`; downlink
reordering is an **assumption** of the channel, not derived from modeled nodes.
The server-only violation follows directly from that assumption: the server
forwards 1 then 2 in order, and the set-based `parent_channel` redelivers 1.

## Actions (all variants)

| Action | Role |
|--------|------|
| `DriverSend` | Next sequence number (`MaxSeq = 3`) |
| `NetworkDrop` | Loss on uplink only |
| `ServerReceive` | Read uplink; optionally forward to `parent_channel` |
| `ParentReceive` | Read downlink; update `parent_view_seq` |

No separate duplicate or drop actions on the downlink. **Redelivery:** receives do
not remove messages from channel sets.

## Ablation modules (guard study)

| Module | Server guard | Parent guard |
|--------|--------------|--------------|
| `SchoolVanTracker_Baseline` | No | No |
| `SchoolVanTracker_ServerGuarded` | Yes | No |
| `SchoolVanTracker_ParentGuarded` | No | Yes |
| `SchoolVanTracker_Guarded` | Yes | Yes |

**Finding (TLC, 2026-10-23):** Under this unordered downlink, **the parent
display guard alone is sufficient** for `MonotonicDisplay`. Server-only guard still
violates (stale frame on `parent_channel` after parent shows a newer seq). Both
guards match production for server/history consistency, not because the server
guard alone secures the map.

### TLC results (cite these in the report)

| Variant | `MonotonicDisplay` | States generated | Distinct states | Depth |
|---------|-------------------|------------------|-----------------|-------|
| Baseline | Violated (stop early) | 282 | 122 | 7 |
| Server guard only | Violated (stop early) | 251 | 97 | 7 |
| Parent guard only | Holds (full graph) | 1726 | **347** | 11 |
| Both guards | Holds (full graph) | 922 | **199** | 11 |

Logs: `tlc/*-monotonic-2026-10-23.txt`. Shortest baseline trace: **7 states**
(two sends, two server receives, two parent receives; parent 2 then 1).

Violation runs stop at the first error (distinct count &lt; full graph). Pass
runs explore the full state space.

## Properties and `Spec`

| Name | Role |
|------|------|
| `MonotonicDisplay` | Safety: display never moves backward |
| `NoFutureFrame` | Invariant: display ≤ `driver_seq` |

`Spec == Init /\ [][Next]_vars` (no fairness). `.cfg` files use
`CHECK_DEADLOCK FALSE` (terminal state when driver done and channels empty).

## Report / PDF

The paper source is `techrxiv/School_Van_Tracking_Preprint.tex`. Its appendix
excerpts `tlc/baseline-monotonic-2026-10-23.txt`; the full logs live in `tlc/`.