---------------- MODULE SchoolVanTracker_PlusCal ----------------
EXTENDS Naturals, TLC

(* --algorithm SchoolVanTracker

variables
    \* Global State Variables
    driver_seq = 0;
    network_buffer = {};
    server_ack_seq = 0;
    parent_view_seq = 0;

\* Define our bounds and properties just like in raw TLA+
define
    MaxSeq == 3
    MonotonicDisplay == [][parent_view_seq' >= parent_view_seq]_parent_view_seq
    NoFutureFrame == parent_view_seq <= driver_seq
    FinalDelivery == (driver_seq = MaxSeq) ~> (parent_view_seq = MaxSeq)
end define;

\* PROCESS 1: The Driver Client
\* Generates monotonic sequences and pushes them to the network.
fair process Driver = "Driver"
begin
    DriveLoop:
        while driver_seq < MaxSeq do
            driver_seq := driver_seq + 1;
            network_buffer := network_buffer \cup {driver_seq};
        end while;
end process;

\* PROCESS 2: The Server and Parent (The Fix)
\* Reads from the unordered network and applies sequence guards.
\* We do not remove messages from the buffer to simulate duplication/re-delivery.
fair process ServerAndParent = "ServerAndParent"
begin
    ReceiveLoop:
        while TRUE do
            \* Wait until there is at least one message in flight
            await network_buffer /= {};
            
            \* Non-deterministically pick ANY message in flight (simulates out-of-order)
            with m \in network_buffer do
                \* Server Guard: only accept if strictly newer
                if m > server_ack_seq then
                    server_ack_seq := m;
                    
                    \* Parent Guard: only update display if strictly newer
                    if m > parent_view_seq then
                        parent_view_seq := m;
                    end if;
                end if;
            end with;
        end while;
end process;

\* PROCESS 3: The Unreliable Network
\* Simulates weak mobile connections by non-deterministically dropping packets.
fair process Network = "Network"
begin
    DropLoop:
        while TRUE do
            await network_buffer /= {};
            with m \in network_buffer do
                network_buffer := network_buffer \ {m};
            end with;
        end while;
end process;

end algorithm; *)

=============================================================================