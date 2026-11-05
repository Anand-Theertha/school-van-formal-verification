---------------- MODULE SchoolVanTracker_PlusCal ----------------
\* PlusCal sketch aligned with SchoolVanTracker_Guarded (not the baseline).
\* Algorithm is commented out; translate in the Toolbox to generate a TLA module.
EXTENDS Naturals, TLC

(* --algorithm SchoolVanTracker

variables
    driver_seq = 0;
    network_buffer = {};
    server_ack_seq = 0;
    parent_channel = {};
    parent_view_seq = 0;

define
    MaxSeq == 3
    MonotonicDisplay == [][parent_view_seq' >= parent_view_seq]_parent_view_seq
    NoFutureFrame == parent_view_seq <= driver_seq
end define;

fair process Driver = "Driver"
begin
    DriveLoop:
        while driver_seq < MaxSeq do
            driver_seq := driver_seq + 1;
            network_buffer := network_buffer \cup {driver_seq};
        end while;
end process;

fair process Server = "Server"
begin
    ServerLoop:
        while TRUE do
            await network_buffer /= {};
            with m \in network_buffer do
                if m > server_ack_seq then
                    server_ack_seq := m;
                    parent_channel := parent_channel \cup {m};
                end if;
            end with;
        end while;
end process;

fair process Parent = "Parent"
begin
    ParentLoop:
        while TRUE do
            await parent_channel /= {};
            with m \in parent_channel do
                if m > parent_view_seq then
                    parent_view_seq := m;
                end if;
            end with;
        end while;
end process;

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
