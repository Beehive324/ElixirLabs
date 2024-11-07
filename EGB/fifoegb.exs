defmodule FIFOReliableBroadcast do
    def start(name, processes) do
        pid = spawn(FIFOReliableBroadcast, :init, [name, processes])
        case :global.re_register_name(name, pid) do
            :yes -> pid
            :no  -> :error
        end
        IO.puts "registered #{name}"
        pid
    end

    def init(name, processes) do
        state = %{
            name: name,
            processes: processes,
            lsn: 0,                     # Local sequence number for messages sent by this process
            pending: MapSet.new(),      # Pending set to track undelivered messages
            next: Map.new(processes, fn p -> {p, 1} end)  # Tracks the next expected sequence number for each process
        }
        run(state)
    end

    def run(state) do
        state = receive do
            # Handle frb.Broadcast event
            {:frb_broadcast, m} ->
                lsn = state.lsn + 1
                data_msg = {:data, state.name, m, lsn}
                beb_broadcast(data_msg, state.processes)

                state = %{state | lsn: lsn}
                state

            # Handle rb.Deliver event
            {:rb_deliver, sender, {:data, s, m, sn}} ->
                pending = MapSet.put(state.pending, {s, m, sn})

                # Process the pending set to deliver messages in FIFO order
                {updated_state, _} = Enum.reduce_while(state.pending, {state, false}, fn {src, msg, seq_no}, {acc_state, _} ->
                    expected_seq = Map.get(acc_state.next, src, 1)

                    if seq_no == expected_seq do
                        # Update next expected sequence number for the source
                        next = Map.put(acc_state.next, src, expected_seq + 1)
                        # Remove the delivered message from pending
                        new_pending = MapSet.delete(acc_state.pending, {src, msg, seq_no})

                        # Trigger frb.Deliver event (simulated with a print statement)
                        IO.puts("#{inspect acc_state.name}: frb.Deliver: #{inspect msg} from #{inspect src}")

                        # Update state with new pending set and next sequence number
                        {updated_state, false} = {%{acc_state | pending: new_pending, next: next}, false}
                        {:cont, {updated_state, false}}
                    else
                        {:halt, {acc_state, true}}
                    end
                end)

                updated_state

            # Handle the termination condition
            :stop -> :ok
        end

        run(state)
    end

    defp unicast(m, p) do
        case :global.whereis_name(p) do
            pid when is_pid(pid) -> send(pid, m)
            :undefined -> :ok
        end
    end

    defp beb_broadcast(m, dest), do: for p <- dest, do: unicast(m, p)
end
