---------------- MODULE SchoolVanTracker_ServerGuarded ----------------
\* Ablation: server sequence guard only; parent applies every downlink delivery.
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
    /\ IF msg > server_ack_seq
       THEN /\ server_ack_seq' = msg
            /\ parent_channel' = parent_channel \cup {msg}
       ELSE UNCHANGED <<server_ack_seq, parent_channel>>
    /\ UNCHANGED <<driver_seq, network_buffer, parent_view_seq>>

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

=============================================================================
