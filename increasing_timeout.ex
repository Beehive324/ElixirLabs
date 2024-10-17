defmodule IncreasingTimeout do

    # start the process
    def start(name, process) do
        pid = spawn(IncreasingTimeout, :init, [name, processes])
        case :global.re_register_name(name, pid) do
             :yes -> pid
             :no  -> :error
        end
        IO.puts "registered #{name}"
        pid
    end

    #initializer method

    def init(name, process) do
        state = %{
            name: name,
            processes: processes,
            delta: 50000,
            alive: MapSet.new(process), #set of alive processes
            suspected: %MapSet{} #set of suspected processes
            delay: 0
        }


    end


    def run(state) do
        state = receive do
            {:timeout} ->
                
                state = check_and_probe(state, state.processes)
                state = %{state | alive: %MapSet{}}
                Process.send_after(self(), {:timeout}, state.delta)
                state

            {:heartbeat_request, pid} ->

                send(pid, {:heartbeat_reply, state.name})
                state
            
            {:heartbeat_reply, name} ->

                %{state | alive: MapSet.put(state.alive, name)}
            
            {:crash, p} ->
                IO.puts("#{state.name}: Crash detected #{p}")
                state
        end
        run(state)

    end

    defp check_and_probe(state, []), do: state
    defp check_and_probe(state, [p | p_tail]) do
         state = if p not in state.alive and p not in state.suspected do
             state = %{state | suspected MapSet.put(state.suspected, p)}
             send(self(), {:crash, p})
             #trigger suspext
        
         else p in state.alive and p in state.suspected do
            state = %{state | suspected MapSet.delete(state.suspected, p)}
            #trigger restore
         end

         alive = MapSet.new()
        

             




    
