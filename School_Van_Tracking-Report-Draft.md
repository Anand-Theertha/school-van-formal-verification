# School Van Tracking: Ordering Guarantees Under Unreliable Networks

Technical report, draft **v0.4** (repository release **v1.2**).  
**Anand Theertha** | October 2026  
Repository: https://github.com/Anand-Theertha/school-van-formal-verification  
Artifact DOI: https://doi.org/10.5281/zenodo.23567442 (new Zenodo version for v1.2 when published)

---

## Abstract

We study the telemetry protocol of a real-time school-van tracking app, where a driver's phone streams GPS positions to parents over unreliable mobile networks. Using TLA+ and the TLC model checker, we model **two unordered channels** (driver→server and server→parent) with **loss on the uplink** and **unbounded redelivery** of the same sequence number (receives do not remove frames from the channel sets). We check that the position shown to a parent never moves backward (`MonotonicDisplay`). TLC reports a violation in the unguarded baseline; a **seven-state** counterexample is documented with raw logs in the repository. An **ablation study** shows that, under this downlink model, **only the parent display guard is necessary** to restore monotonicity—a server-only guard still allows the map to jump backward when frames 1 and 2 both sit on the parent channel. Production uses **both** guards so server state and ancillary consumers (e.g. history) stay consistent, not because the server guard alone secures the map. We also tested the implementation with injected duplicate, reordered, and batched frames. We state what the model does and does not prove, and outline v2 work (session epoch, shared ack state, acknowledgements).

---

## 1. Problem

A parent who sees a stale or backward-jumping vehicle position may make a wrong decision about their child, so correctness matters more here than in most consumer apps. Vehicles pass through cellular dead zones, so connections drop, the driver app buffers positions, and frames are uploaded in bursts when the connection returns. In an early field test on a weak network, a dropped connection did not recover and a parent's map showed a stale, incorrect location. This report asks: what ordering guarantee can the system state, and how can it be checked before release?

---

## 2. System overview

The driver app samples GPS every 2 seconds and sends each position as a frame with a trip id, a sequence number (`seq_id`), a timestamp, and coordinates. The path is:

1. Driver app (React Native) sends frames over Socket.IO on secure WebSockets.
2. One or more Node.js ingestion nodes validate the token, persist the frame to PostgreSQL/PostGIS, update the current-trip cache, and publish through a Redis pub/sub adapter.
3. Parent apps subscribed to the trip receive the broadcast and render the position.

The update rate is bounded by the 2-second sampling interval (average end-to-end latency ~250 ms on 4G). Appendix A gives the full stack and schema.

---

## 3. Baseline protocol and failure model

**Baseline protocol.** The server accepts each valid frame and broadcasts it. Without sequence guards, the parent display follows whatever arrives on the downlink.

**Failure model.**

- Connections can drop and reconnect.
- Frames can be duplicated by application-level retries.
- Frames from an old connection can arrive after frames from a new one.
- Several server nodes can process frames for the same trip concurrently.

**Out of scope.** GPS error, dead reckoning, map matching, and malicious clients.

---

## 4. Formal model (TLA+)

### 4.1 Channel abstraction and why it is justified

TCP and WebSockets do not reorder frames within one connection. The model nevertheless uses **unordered** channels, because that is a conservative abstraction of: overlapping old and new sockets during reconnect, application-level retries, and parallel processing on multiple server nodes.

We use **two** channels:

- **Uplink (`network_buffer`):** driver → ingestion server; **lossy** (`NetworkDrop`).
- **Downlink (`parent_channel`):** server → parent; **unordered** in the model.

**Deployment note:** Redis pub/sub may preserve order from a **single** publisher. We model an unordered downlink because **multiple ingestion nodes** can publish toward the same trip, so parents need not see frames in send order.

**Duplication** is not modeled as separate “duplicate” actions. Each channel is a **set of sequence numbers**; **receives do not remove** an element, so the same `seq_id` can be delivered arbitrarily many times (redelivery). We do not model two distinct in-flight copies of the same `seq_id` in one set (a multiset would be needed for that).

A counterexample in this model shows the **protocol abstract** can violate a property under these assumptions; it is **not** a proof about the live cellular network.

### 4.2 State variables

| Variable | Meaning |
|----------|---------|
| `driver_seq` | Latest sequence number produced by the driver |
| `network_buffer` | Set of sequence numbers in flight on the driver→server path |
| `server_ack_seq` | Highest sequence number the server has accepted |
| `parent_channel` | Set of sequence numbers forwarded toward the parent |
| `parent_view_seq` | Sequence number currently displayed to the parent |

### 4.3 Actions

The specifications include exactly these actions (no separate “connection drop” or “duplicate” operators):

| Action | Description |
|--------|-------------|
| `DriverSend` | Driver produces the next frame (`driver_seq` increases, up to `MaxSeq`) |
| `NetworkDrop` | Uplink loss: remove one frame from `network_buffer` |
| `ServerReceive` | Server reads one frame from `network_buffer`; may append to `parent_channel` |
| `ParentReceive` | Parent reads one frame from `parent_channel`; updates `parent_view_seq` |

**Modules** (ablation): `SchoolVanTracker_Baseline` (no guards); `SchoolVanTracker_ServerGuarded` (server guard only); `SchoolVanTracker_ParentGuarded` (parent guard only); `SchoolVanTracker_Guarded` (both guards, as deployed).

### 4.4 Bounds and specification

- **`MaxSeq = 3`** in all modules (finite state space for TLC).
- **No bound** on drops or redeliveries beyond finiteness of the model.
- **`Spec == Init /\ [][Next]_vars`** with **no fairness** hypothesis for the safety runs below.
- TLC configs set **`CHECK_DEADLOCK FALSE`** (terminal states exist when the driver has finished and both channels are empty).

---

## 5. Properties

**Safety (action property):** the displayed position never moves backward.

```text
MonotonicDisplay == [][parent_view_seq' >= parent_view_seq]_parent_view_seq
```

**Safety (invariant):** only positions the driver has produced are displayed.

```text
NoFutureFrame == parent_view_seq <= driver_seq
```

**Liveness (not checked in current TLC configs):**

```text
FinalDelivery == (driver_seq = MaxSeq) ~> (parent_view_seq = MaxSeq)
```

`FinalDelivery` requires stronger fairness, bounded loss, or retransmission. Section 9 discusses acknowledgements for v2. The v1 TLC runs check **`MonotonicDisplay`** and **`NoFutureFrame`** only.

---

## 6. Results

**Environment:** TLC 2.20 (`tla2tools.jar` via VS Code TLA+ extension), Temurin JDK 25, Windows 11, 2026-10-23. Raw logs: repository `tlc/` (Appendix B).

### 6.1 Baseline protocol

TLC **violates** `MonotonicDisplay`. Shortest counterexample: **7 states** (six steps: two `DriverSend`, two server receives, two parent receives).

| State | Summary |
|-------|---------|
| 1 | Init |
| 2–3 | Driver sends seq 1 and 2; `network_buffer = {1,2}` |
| 4–5 | Server accepts 1 then 2; `parent_channel = {1,2}` |
| 6 | Parent displays 2 (`parent_view_seq = 2`) |
| 7 | Parent applies 1 → `parent_view_seq = 1` (**violation**) |

Reordering on the **downlink** suffices; uplink duplication is not required for this trace. See `tlc/baseline-monotonic-2026-10-23.txt`.

At error: **282** states generated, **122** distinct (search stopped with **64** states left on queue). Trace depth **7**.

### 6.2 Guard ablation (`MonotonicDisplay`)

| Variant | Module | Result | Generated | Distinct | Depth |
|---------|--------|--------|-----------|----------|-------|
| No guards | `SchoolVanTracker_Baseline` | **Violated** | 282 | 122† | 7 |
| Server guard only | `SchoolVanTracker_ServerGuarded` | **Violated** | 251 | 97† | 7 |
| Parent guard only | `SchoolVanTracker_ParentGuarded` | **Holds** | 1726 | 347 | 11 |
| Both guards (v1) | `SchoolVanTracker_Guarded` | **Holds** | 922 | 199 | 11 |

†First violation stops exploration early; distinct counts are **not** the full state graph. Full exploration on passing runs: **347** distinct (parent-only) matches the unguarded state space size with a display guard; **199** distinct when both guards prune uplink forwarding.

**Conclusion:** Under an unordered `parent_channel`, the **parent guard is necessary** for `MonotonicDisplay`. The **server guard alone does not** prevent backward map updates. Both guards remain appropriate in production for server/history consistency and stale-frame filtering on the uplink.

*“Holds” means no violation within `MaxSeq = 3` and the stated channel model; it is not a proof for unbounded sequences or all real-network behaviors.*

### 6.3 Liveness

`FinalDelivery` was **not** run in the bundled `.cfg` files. Informally, without driver-side retention and server acknowledgements, a lost final frame can leave the parent view stalled (aligned with injection test T6). That is a **design trade-off** for v1: safety properties above were the focus of model checking.

---

## 7. Protocol revisions (v1 as built)

**Server filter:** Drop any frame whose sequence number is less than or equal to the server's current highest seen value for that trip (uplink guard).

**Parent guard:** Render a frame only if its sequence number is greater than the last one displayed.

TLC ablation (Section 6.2) justifies treating the **parent guard as necessary for monotonic display** under the modeled downlink; the **server guard** supports consistent server state and consumers other than the live map.

---

## 8. Implementation test (fault injection)

| Test | Injected fault | Expected after fix | Baseline | v1 |
|------|----------------|-------------------|----------|-----|
| T1 | Old frame after newer | No backward jump | 14 jumps | 0 jumps |
| T2 | Duplicate frame | No visible change | UI flickers | Ignored |
| T3 | Burst after reconnect | Final position correct | Jumps | Correct |
| T4 | Driver restart, counter resets | Frames accepted | Accepted | Dropped (stale) |
| T5 | Two nodes concurrent | No backward jump | Jumps | Race condition |
| T6 | Last frame lost before reconnect | Final position shown | Stalls | Stalls |

---

## 9. Limitations and future work (v2)

- **Session epoch** (T4): local `seq_id` reset without epoch freezes the trip.
- **Idempotent history:** store all frames with `(trip, epoch, sequence)`; separate history from live broadcast.
- **Shared server state** (T5): atomic Redis update for highest seen seq across nodes.
- **Acknowledgements and retransmission** (T6): needed for `FinalDelivery`-style liveness.
- **Model:** optional multiset for duplicate in-flight copies; explicit downlink loss; per-action fairness for liveness checks.

---

## 10. Related work

Applied case study. TLA+ and TLC: Lamport, *Specifying Systems*. Kleppmann, *Designing Data-Intensive Applications* (ordering, idempotency). Lamport, “Time, Clocks, and the Ordering of Events in a Distributed System” (1978). Beschastnikh et al., “Debugging distributed systems” (*CACM*, 2016).

---

## Appendix A: Architecture and schema

*(Unchanged from draft v0.3 — stack, schema, security, design decisions.)*

**Stack.** Node.js/Express; Socket.IO over WSS with Redis pub/sub; PostgreSQL 15 + PostGIS; React Native driver/parent apps.

**Schema.** Users, Routes, Children, Trips, Locations (`seq_id`, PostGIS, time partitioning).

**Security.** JWT (RS256); bcrypt; role-based publish/subscribe; TLS 1.3.

**Design decisions.** WebSockets over polling; PostgreSQL/PostGIS over MongoDB; shared ordering responsibility across driver, server, and parent.

---

## Appendix B: TLC logs (unedited)

Included in the repository release:

- `tlc/baseline-monotonic-2026-10-23.txt`
- `tlc/server-guarded-monotonic-2026-10-23.txt`
- `tlc/parent-guarded-monotonic-2026-10-23.txt`
- `tlc/both-guarded-monotonic-2026-10-23.txt`

For print/PDF appendix, paste these files verbatim or link to the tagged release archive.

---

## Revision history

| Draft | Changes |
|-------|---------|
| v0.3 | Initial structure; placeholder TLC; merged-channel narrative |
| v0.4 | Two-channel TLA+ specs; real TLC logs; guard ablation; parent-guard necessity; align actions/bounds with `.tla`; soften “proves network” wording |
