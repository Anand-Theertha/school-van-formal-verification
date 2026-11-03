---------------- MODULE SchoolVanTracker_ParentGuarded ----------------
\* Ablation: parent display guard only; server forwards every accepted uplink frame.
EXTENDS Naturals

VARIABLES
    driver_seq,
    network_buffer,
    server_ack_seq,
    parent_channel,
    parent_view_seq

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

ServerReceive(msg) ==
    /\ msg \in network_buffer
    /\ server_ack_seq' = msg
    /\ parent_channel' = parent_channel \cup {msg}
    /\ UNCHANGED <<driver_seq, network_buffer, parent_view_seq>>

ParentReceive(msg) ==
    /\ msg \in parent_channel
    /\ IF msg > parent_view_seq
       THEN parent_view_seq' = msg
       ELSE UNCHANGED parent_view_seq
    /\ UNCHANGED <<driver_seq, network_buffer, server_ack_seq, parent_channel>>

Next ==
    \/ DriverSend
    \/ \E m \in network_buffer : NetworkDrop(m)
    \/ \E m \in network_buffer : ServerReceive(m)
    \/ \E m \in parent_channel : ParentReceive(m)

Spec == Init /\ [][Next]_vars

MonotonicDisplay == [][parent_view_seq' >= parent_view_seq]_parent_view_seq
NoFutureFrame == parent_view_seq <= driver_seq

=============================================================================
