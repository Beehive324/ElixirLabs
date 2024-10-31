defmodule ReliableFIFOBroadcast do
    def start(name, processes, client \\ :none) do
        pid = spawn(ReliableFIFOBroadcast, :init, [name, processes, client])
        case :global.re_register_name(name, pid) do
            :yes -> pid  
            :no  -> :error
        end
        IO.puts "registered #{name}"
        pid
    end

    # Init event must be the first
    # one after the component is created
    def init(name, processes, client) do 
        start_beb(name)
        state = %{ 
            name: name, 
            client: (if is_pid(client), do: client, else: self()),
            processes: processes,
            next: (for p <- processes, into: %{}, do: {p, 1}) #initialize all processes with a value with 1
            
            # Add state components below as necessary
            
        }
        run(state)
    end

    # Helper functions: DO NOT REMOVE OR MODIFY
    defp get_beb_name() do 
        {:registered_name, parent} = Process.info(self(), :registered_name)
        String.to_atom(Atom.to_string(parent) <> "_beb")
    end

    defp start_beb(name) do
        Process.register(self(), name)
        pid = spawn(BestEffortBroadcast, :init, [])
        Process.register(pid, get_beb_name())
        Process.link(pid)
    end

    defp beb_broadcast(m, dest) do
        BestEffortBroadcast.beb_broadcast(Process.whereis(get_beb_name()), m, dest)       
    end
    # End of helper functions

    def run(state) do
        state = receive do 
            {:broadcast, m} -> 
                # add code to handle client broadcast requests
                
                data_msg = {:data, state.name, state.next}
                
                
                beb_broadcast(data_msg, m)

                state

            # Add further message handlers as necessary

            # Message handle for delivery event if started without the client argument
            # (i.e., this process is the default client); optional, but useful for debugging
            {:deliver, pid, proc, m} ->
                IO.puts("#{inspect state.name}, #{inspect pid}: RFIFO-deliver: #{inspect m} from #{inspect proc}")
                state
        end
        run(state)
    end

    # Add auxiliary functions as necessary

end
