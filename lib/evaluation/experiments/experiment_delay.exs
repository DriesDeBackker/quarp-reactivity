alias Observables.Subject
alias Observables.Obs
alias ReactiveMiddleware.Registry
alias Reactivity.DSL.Signal
alias Evaluation.Graph.GraphCreation
alias Evaluation.Graph
alias Evaluation.Commands.CommandsGeneration
alias Evaluation.Commands.CommandsInterpretation
alias Evaluation.Adaptations.SignalEval

# Experiment set-up for measuring mean total propagation delay.

guarantee = {:g, 0}

params = [
	hosts: [
		:"nerves@192.168.1.245", 
		:"nerves@192.168.1.143", 
		:"nerves@192.168.1.199", 
 		:"nerves@192.168.1.224", 
 		:"nerves@192.168.1.247"],
	nb_of_vars: 5,
	graph_depth: 10,
	signals_per_level_avg: 2,
	deps_per_signal_avg: 2,
	nodes_locality: 0.5,
	update_interval_mean: 2000,
	update_interval_sd: 100,
	experiment_length: 30_000]

Registry.set_guarantee(guarantee)

exp_handle = Subject.create
exp_handle
|> Signal.from_plain_obs
|> Signal.register(:exp)

var = fn name, im, isd ->
	fn -> 
		var_handle = Subject.create
		run = fn
			f -> 
				if Signal.signal(:exp) |> Signal.evaluate == true do
					Subject.next(var_handle, {name, round(:erlang.monotonic_time / 1000_000)})
				end
				:timer.sleep(round(:rand.normal(im, isd*isd)))
				f.(f)
			end
		Task.start fn -> run.(run) end
		var_handle
		|> Signal.from_plain_obs
		|> Signal.register(name)
	end
end

prop = fn name, ts ->
	fn -> 
		Signal.signal(ts)
		|> Signal.liftapp(fn x -> x end)
		|> Signal.register(name)
		:ok
	end
end

fake_mean2 = fn name, ts1, ts2 ->
	fn -> 
		sts1 = Signal.signal(ts1)
		sts2 = Signal.signal(ts2)
		SignalEval.liftapp_eval([sts1, sts2],
			fn {_n1, v1}, {_n2, v2} -> round((v1 + v2) / 2) end)
		|> Signal.register(name)
		:ok
	end
end

fake_mean3 = fn name, ts1, ts2, ts3 ->
	fn ->
		sts1 = Signal.signal(ts1)
		sts2 = Signal.signal(ts2)
		sts3 = Signal.signal(ts3)
		SignalEval.liftapp_eval([sts1, sts2, sts3],
			fn {_n1, v1}, {_n2, v2}, {_n3, v3} -> round((v1 + v2 + v3) / 3) end)
		|> Signal.register(name)
		:ok
	end
end

fake_mean4 = fn name, ts1, ts2, ts3, ts4 ->
	fn -> 
		sts1 = Signal.signal(ts1)
		sts2 = Signal.signal(ts2)
		sts3 = Signal.signal(ts3)
		sts4 = Signal.signal(ts4)
		SignalEval.liftapp_eval([sts1, sts2, sts3, sts4],
			fn {_n1, v1}, {_n2, v2}, {_n3, v3}, {_n4, v4} -> round((v1 + v2 + v3 + v4) / 4) end)
		|> Signal.register(name)
		:ok
	end
end

final = fn var, fname ->
	fn -> 
		Signal.signal(fname)
		|> Obs.filter(fn {{xn, _xt}, _cxt} -> xn == var end)
		|> Signal.liftapp(fn {_xn, xt} -> [{xt, round(:erlang.monotonic_time / 1000_000)}] end)
		|> Signal.scan(fn [tup], acc -> [tup | acc] end)
		|> Signal.register(String.to_atom(Atom.to_string(var) <> "_" <> Atom.to_string(fname)))
		:ok
	end
end

g = GraphCreation.generateGraph(params)
cs = CommandsGeneration.generateCommandsDelay(g, params)
cs
|> Enum.each(fn c -> IO.puts(inspect c) end)
cs
|> CommandsInterpretation.interpretCommandsDelay({var, prop, fake_mean2, fake_mean3, fake_mean4, final})

Subject.next(exp_handle, true)
:timer.sleep(Keyword.get(params, :experiment_length))
Subject.next(exp_handle, false)
:timer.sleep(1000)


vars = Graph.getVars(g)
finals = 
	vars 
	|> Enum.map(fn v -> Graph.getFinalNodesForVar(g, v) end)
means = 
	vars
	|> Enum.zip(finals)
	|> Enum.filter(fn {v, [f | _ft]} -> f != v end)
	|> Enum.map(
		fn {v, fs} ->
			names = 
				fs
				|> Enum.map(fn f -> String.to_atom(Atom.to_string(v) <> "_" <> Atom.to_string(f)) end)
			IO.puts(inspect(names))
			signals = 
				names
				|> Enum.map(fn vf -> Signal.signal(vf) end)
			IO.puts(inspect(signals))
			results = 
				signals
				|> Enum.map(fn sf -> Signal.evaluate(sf) end)
			IO.puts(inspect(results))
			concatenated = 
				results
				|> Enum.concat
			IO.puts(inspect(concatenated))
			grouped = 
				concatenated
				|> Enum.group_by(fn {xt, _xr} -> xt end)
				|> Map.to_list
				|> Enum.map(fn {xt, xrs} -> {xt, xrs |> Enum.map(fn {_xt, xr} -> xr end)} end)
			IO.puts(inspect(grouped))
			full = 
				grouped
				|> Enum.filter(fn {_xt, xrs} -> Enum.count(xrs) == Enum.count(fs) end)
			IO.puts(inspect(full))
			maxes = 
				full
				|> Enum.map(fn {xt, xrs} -> {xt, Enum.max(xrs)} end)
			IO.puts(inspect(maxes))
			delays = 
				maxes
				|> Enum.map(fn {xt, max} -> max - xt end)
			IO.puts(inspect(delays))
			delays
		end)
	|> List.flatten
mean = round(Enum.sum(means) / Enum.count(means))
IO.puts("Mean total propagation delay: #{mean}")