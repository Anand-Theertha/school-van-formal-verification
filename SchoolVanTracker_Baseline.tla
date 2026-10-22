---------------- MODULE SchoolVanTracker_Baseline ----------------
EXTENDS Naturals

VARIABLES
    driver_seq,      \* Sequence number of the latest frame the driver produced
    network_buffer,  \* Set of in-flight frames, each with a sequence number and payload
    server_ack_seq,  \* Highest sequence number the server has accepted
    parent_view_seq  \* Sequence number of the position currently displayed to the parent

vars == <<driver_seq, network_buffer, server_ack_seq, parent_view_seq>>

MaxSeq == 3

Init ==
    /\ driver_seq = 0
    /\ network_buffer = {}
    /\ server_ack_seq = 0
    /\ parent_view_seq = 0

\* Driver app generates a new GPS frame (Bounded to MaxSeq)
DriverSend ==
    /\ driver_seq < MaxSeq  
    /\ driver_seq' = driver_seq + 1
    /\ network_buffer' = network_buffer \cup {driver_seq + 1}
    /\ UNCHANGED <<server_ack_seq, parent_view_seq>>

\* The channel can drop frames (Unreliable network)
NetworkDrop(msg) ==
    /\ msg \in network_buffer
    /\ network_buffer' = network_buffer \ {msg}
    /\ UNCHANGED <<driver_seq, server_ack_seq, parent_view_seq>>

\* Baseline Server: Accepts anything in the buffer and broadcasts it
ServerAndParentReceive(msg) ==
    /\ msg \in network_buffer
    /\ server_ack_seq' = msg
    /\ parent_view_seq' = msg
    /\ UNCHANGED <<driver_seq, network_buffer>>

Next == 
    \/ DriverSend 
    \/ \E m \in network_buffer : NetworkDrop(m)
    \/ \E m \in network_buffer : ServerAndParentReceive(m)

Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

\* Properties
MonotonicDisplay == [][parent_view_seq' >= parent_view_seq]_parent_view_seq
NoFutureFrame == parent_view_seq <= driver_seq
FinalDelivery == (driver_seq = MaxSeq) ~> (parent_view_seq = MaxSeq)

=============================================================================