---------------- MODULE SchoolVanTracker_Baseline ----------------
\* Baseline protocol: unordered driver-to-server channel; server forwards
\* accepted frames to a separate parent channel; parent applies every delivery.
\* Frames are not removed on receive, so the same sequence number can be
\* delivered arbitrarily many times (redelivery), not multiple distinct copies
\* in the set.
EXTENDS Naturals

VARIABLES
    driver_seq,       \* Latest sequence number produced by the driver
    network_buffer,   \* Set of in-flight frames on the driver-to-server path
    server_ack_seq,   \* Highest sequence number the server has accepted
    parent_channel,   \* Set of frames the server has forwarded toward the parent
    parent_view_seq   \* Sequence number shown to the parent

vars == <<driver_seq, network_buffer, server_ack_seq, parent_channel, parent_view_seq>>

MaxSeq == 3

Init ==
    /\ driver_seq = 0
    /\ network_buffer = {}
    /\ server_ack_seq = 0
    /\ parent_channel = {}
    /\ parent_view_seq = 0

DriverSend ==
    /\ driver_seq < MaxSeq
    /\ driver_seq' = driver_seq + 1
    /\ network_buffer' = network_buffer \cup {driver_seq + 1}
    /\ UNCHANGED <<server_ack_seq, parent_channel, parent_view_seq>>

NetworkDrop(msg) ==
    /\ msg \in network_buffer
    /\ network_buffer' = network_buffer \ {msg}
    /\ UNCHANGED <<driver_seq, server_ack_seq, parent_channel, parent_view_seq>>

\* Server reads from the driver-to-server channel (no sequence guard).
ServerReceive(msg) ==
    /\ msg \in network_buffer
    /\ server_ack_seq' = msg
    /\ parent_channel' = parent_channel \cup {msg}
    /\ UNCHANGED <<driver_seq, network_buffer, parent_view_seq>>

\* Parent reads from the server-to-parent channel (no display guard).
ParentReceive(msg) ==
    /\ msg \in parent_channel
    /\ parent_view_seq' = msg
    /\ UNCHANGED <<driver_seq, network_buffer, server_ack_seq, parent_channel>>

Next ==
    \/ DriverSend
    \/ \E m \in network_buffer : NetworkDrop(m)
    \/ \E m \in network_buffer : ServerReceive(m)
    \/ \E m \in parent_channel : ParentReceive(m)

Spec == Init /\ [][Next]_vars

MonotonicDisplay == [][parent_view_seq' >= parent_view_seq]_parent_view_seq
NoFutureFrame == parent_view_seq <= driver_seq
\* FinalDelivery (liveness) omitted until fairness and retransmission are modeled.

=============================================================================
