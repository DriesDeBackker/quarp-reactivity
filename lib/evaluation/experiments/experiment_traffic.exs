alias Observables.Subject
alias Observables.Obs
alias ReactiveMiddleware.Registry
alias Reactivity.DSL.{Signal, EventStream, Behaviour}
alias Evaluation.Graph.GraphCreation
alias Evaluation.Commands.CommandsGeneration
alias Evaluation.Commands.CommandsInterpretation

# Experiment set-up for measuring network traffic (e.g. using Wireshark).

guarantee = {:g, 0}

params = [
	hosts: [
		:"nerves@192.168.1.247", 
		:"nerves@192.168.1.144", 
		:"nerves@192.168.1.200",
 		:"nerves@192.168.1.225", 
 		:"nerves@192.168.1.248"],
	nb_of_vars: 10,
	graph_depth: 5,
	signals_per_level_avg: 2,
	deps_per_signal_avg: 2,
	nodes_locality: 0.5,
	values_mean: 100,
	values_sd: 15,
	update_interval_mean: 1000,
	update_interval_sd: 150,
	experiment_length: 90_000,
]


#Registry.set_guarantee(guarantee)

var = fn name, im, isd, vm, vsd ->
	fn -> 
		var_handle = Subject.create
		run = fn
			f -> 
				val = :rand.normal(vm, vsd*vsd) |> round
				IO.puts("Var #{name} has a new value: #{val}")
				Subject.next(var_handle, val)
				:timer.sleep(round(:rand.normal(im, isd*isd)))
				f.(f)
			end
		Task.start fn -> run.(run) end
		var_handle
		|> Signal.from_plain_obs
		|> Signal.register(name)
	end
end

mean1 = fn name, dep->
	fn -> 
		Signal.signal(dep)
		|> Signal.liftapp(fn x -> x end)
		|> Signal.register(name)
		:ok
	end
end

mean2 = fn name, dep1, dep2 ->
	fn -> 
		sig1 = Signal.signal(dep1)
		sig2 = Signal.signal(dep2)
		Signal.liftapp([sig1, sig2], 
			fn x, y -> 
				val = round((x + y) / 2)
				IO.puts("Signal #{name} has a new value: #{val}")
				val
			end)
		|> Signal.register(name)
		:ok
	end
end

mean3 = fn name, dep1, dep2, dep3 ->
	fn ->
		sig1 = Signal.signal(dep1)
		sig2 = Signal.signal(dep2)
		sig3 = Signal.signal(dep3)
		Signal.liftapp([sig1, sig2, sig3], 
			fn x, y, z -> 
				val = round((x + y + z) / 3)
				IO.puts("Signal #{name} has a new value: #{val}")
				val
			end)
		|> Signal.register(name)
		:ok
	end
end

mean4 = fn name, dep1, dep2, dep3, dep4 ->
	fn -> 
		sig1 = Signal.signal(dep1)
		sig2 = Signal.signal(dep2)
		sig3 = Signal.signal(dep3)
		sig4 = Signal.signal(dep4)
		Signal.liftapp([sig1, sig2, sig3, sig4], 
			fn v, w, x, y -> 
				val = round((v + w + x + y) / 4)
				IO.puts("Signal #{name} has a new value: #{val}")
				val
			end)
		|> Signal.register(name)
		:ok
	end
end

cs = GraphCreation.generateGraph(params)
|> CommandsGeneration.generateCommandsTraffic(params)
cs
|> Enum.each(fn c -> IO.puts(inspect c) end)
cs
|> CommandsInterpretation.interpretCommandsTraffic({var, mean1, mean2, mean3, mean4})

IO.puts("EXPERIMENT STARTED")
:timer.sleep(Keyword.get(params, :experiment_length))
IO.puts("EXPERIMENT ENDED")