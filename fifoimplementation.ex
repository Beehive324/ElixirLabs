defmodule FIFOEagerReliableBroadcast do

    def start() do
        pid = spawn(FIFOEeagerReliableBroadcast, :init[name, processes])
        case :global.re_register_name(name, pid) do
            :yes -> pid
            :no  -> error
        end
        IO.puts "registered #{name}"
        pid
    end


    def init(name, processes) do
        state = %{
            name: name,
            processes: processes,
            delivered: %MapSet{},
            next: (for p <- processes, into: %{}, do: {p, 1}) #initialize all processes with a value with 1
            seq_no: 0
        }

    end

    def run(state) do
        state = receive do
            {: broadcast, m} ->
                
                
                data = {:data, state.name, state.seq_no, m}
                EagerReliableBroadcast(data)
                state = %{state | seq_no: state.seq_no + 1}
                state
                state = %{state | next: Map.put(state.next, ({process})) } 
                
    
                {:data, proc, seq_no, m} ->
                    state = if {{data}} in state and state.seq_no != next.get(state.seq_no) do
                        state = %{state | next: }
            end
            
            

    end

end
