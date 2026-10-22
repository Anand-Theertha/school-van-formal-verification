---------------- MODULE SchoolVanTracker_Guarded ----------------
EXTENDS Naturals

VARIABLES
    driver_seq,
    network_buffer,
    server_ack_seq,
    parent_view_seq

vars == <<driver_seq, network_buffer, server_ack_seq, parent_view_seq>>
MaxSeq == 3

Init ==
    /\ driver_seq = 0
    /\ network_buffer = {}
    /\ server_ack_seq = 0
    /\ parent_view_seq = 0

DriverSend ==
    /\ driver_seq < MaxSeq  
    /\ driver_seq' = driver_seq + 1
    /\ network_buffer' = network_buffer \cup {driver_seq + 1}
    /\ UNCHANGED <<server_ack_seq, parent_view_seq>>

NetworkDrop(msg) ==
    /\ msg \in network_buffer
    /\ network_buffer' = network_buffer \ {msg}
    /\ UNCHANGED <<driver_seq, server_ack_seq, parent_view_seq>>

\* V1 Fix: The server drops frames <= the highest seen, and the parent 
\* only renders if incoming > parent_view_seq
ServerAndParentReceive(msg) ==
    /\ msg \in network_buffer
    /\ IF msg > server_ack_seq 
       THEN /\ server_ack_seq' = msg
            /\ parent_view_seq' = IF msg > parent_view_seq THEN msg ELSE parent_view_seq
       ELSE UNCHANGED <<server_ack_seq, parent_view_seq>>
    /\ UNCHANGED <<driver_seq, network_buffer>>

Next == 
    \/ DriverSend 
    \/ \E m \in network_buffer : NetworkDrop(m)
    \/ \E m \in network_buffer : ServerAndParentReceive(m)

Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

MonotonicDisplay == [][parent_view_seq' >= parent_view_seq]_parent_view_seq
NoFutureFrame == parent_view_seq <= driver_seq
FinalDelivery == (driver_seq = MaxSeq) ~> (parent_view_seq = MaxSeq)

=============================================================================