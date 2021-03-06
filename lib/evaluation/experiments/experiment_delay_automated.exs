alias Observables.Subject
alias Observables.Obs
alias ReactiveMiddleware.Registry
alias Reactivity.DSL.Signal
alias Evaluation.Graph.GraphCreation
alias Evaluation.Graph
alias Evaluation.Commands.CommandsGeneration
alias Evaluation.Commands.CommandsInterpretation
alias Evaluation.Adaptations.SignalEval

##########
# SET-UP #
##########

guarantee = nil
#guarantee = {:g, 0}

params = [
	hosts: [
		:"nerves@192.168.1.248", 
		:"nerves@192.168.1.144", 
		:"nerves@192.168.1.200", 
 		:"nerves@192.168.1.225", 
 		:"nerves@192.168.1.246"],
	nb_of_vars: 10,
	graph_depth: 5,
	signals_per_level_avg: 2,
	deps_per_signal_avg: 2,
	nodes_locality: 0.5,
	update_interval_mean: 1000,
	update_interval_sd: 150,
	experiment_length: 20_000,
	name: "standard"]

sample_size = 3

nb_of_vars_range = [3, 4, 5, 20]
graph_depth_range = [3, 4, 10, 20]
signals_per_level_range = [1, 5, 10, 20]
deps_per_signal_range = [1, 3, 4, 5]
locality_range = [0.0, 0.25, 0.75, 1.0]

vars_params = 
	nb_of_vars_range
	|> Enum.map(
		fn nb ->
			params
			|> Keyword.put(:nb_of_vars, nb)
			|> Keyword.put(:name, "vars: " <> to_string(nb))
		end)

graph_depth_params = 
	graph_depth_range
	|> Enum.map(
		fn d ->
			params
			|> Keyword.put(:graph_depth, d)
			|> Keyword.put(:name, "depth: " <> to_string(d))
		end)

signals_per_level_params = 
	signals_per_level_range
	|> Enum.map(
		fn spl ->
			params
			|> Keyword.put(:signals_per_level_avg, spl)
			|> Keyword.put(:name, "sigsperlvl: " <> to_string(spl))
		end)

deps_per_signal_params = 
	deps_per_signal_range
	|> Enum.map(
		fn dps ->
			params
			|> Keyword.put(:deps_per_signal_avg, dps)
			|> Keyword.put(:name, "depspersig: " <> to_string(dps))
		end)

locality_params = 
	locality_range
	|> Enum.map(
		fn l ->
			params
			|> Keyword.put(:locality_range, l)
			|> Keyword.put(:name, "locality" <> to_string(l))
		end)

paramslist =
	# vars_params ++
	graph_depth_params ++
	signals_per_level_params ++
	deps_per_signal_params ++
	locality_params

var = fn name, im, isd ->
	fn -> 
		var_handle = Subject.create
		run = fn
			f -> 
				case Signal.signal(:exp) |> Signal.evaluate do
					:idle -> 
						:timer.sleep(round(:rand.normal(im, isd*isd)))
						f.(f)
					:running -> 
						val = round(:erlang.monotonic_time / 1000_000)
						Subject.next(var_handle, {name, val})
						:timer.sleep(round(:rand.normal(im, isd*isd)))
						f.(f)
					:done ->
						Subject.done(var_handle)
				end
			end
		Task.start fn -> run.(run) end
		sig = 
			var_handle
			|> Signal.from_plain_obs
			|> Signal.register(name)
		#sig
		#|> Signal.liftapp(fn x -> "Var #{name} has a new value: #{inspect x}" end)
		#|> Signal.print
	end
end

prop = fn name, ts ->
	fn -> 
		sig = 
			ts
			|> Signal.signal
			|> Signal.liftapp(fn x -> x end)
			|> Signal.register(name)
		#sig
		#|> Signal.liftapp(fn x -> "Signal #{name} has a new value: #{inspect x}" end)
		#|> Signal.print
		:ok
	end
end

fake_mean2 = fn name, ts1, ts2 ->
	fn -> 
		sts1 = Signal.signal(ts1)
		sts2 = Signal.signal(ts2)
		sig = 
			SignalEval.liftapp_eval([sts1, sts2],
				fn {_n1, v1}, {_n2, v2} -> round((v1 + v2) / 2) end)
			|> Signal.register(name)
		#sig
		#|> Signal.liftapp(fn x -> "Signal #{name} has a new value: #{inspect x}" end)
		#|> Signal.print
		:ok
	end
end

fake_mean3 = fn name, ts1, ts2, ts3 ->
	fn ->
		sts1 = Signal.signal(ts1)
		sts2 = Signal.signal(ts2)
		sts3 = Signal.signal(ts3)
		sig = 
			SignalEval.liftapp_eval([sts1, sts2, sts3],
				fn {_n1, v1}, {_n2, v2}, {_n3, v3} -> round((v1 + v2 + v3) / 3) end)
			|> Signal.register(name)
		#sig
		#|> Signal.liftapp(fn x -> "Signal #{name} has a new value: #{inspect x}" end)
		#|> Signal.print
		:ok
	end
end

fake_mean4 = fn name, ts1, ts2, ts3, ts4 ->
	fn -> 
		sts1 = Signal.signal(ts1)
		sts2 = Signal.signal(ts2)
		sts3 = Signal.signal(ts3)
		sts4 = Signal.signal(ts4)
		sig = 
			SignalEval.liftapp_eval([sts1, sts2, sts3, sts4],
				fn {_n1, v1}, {_n2, v2}, {_n3, v3}, {_n4, v4} -> round((v1 + v2 + v3 + v4) / 4) end)
			|> Signal.register(name)
		#sig
		#|> Signal.liftapp(fn x -> "Signal #{name} has a new value: #{inspect x}" end)
		#|> Signal.print
		:ok
	end
end

final = fn var, fname ->
	fn -> 
		{:signal, sobs} = Signal.signal(fname)
		fsobs =
			sobs
			|> Obs.filter(fn {{xn, _xt}, _cxt} -> xn == var end)
		name = String.to_atom(Atom.to_string(var) <> "_" <> Atom.to_string(fname))
		sig =
			{:signal, fsobs}
			|> Signal.liftapp(fn {_xn, xt} -> [{xt, round(:erlang.monotonic_time / 1000_000)}] end)
			|> Signal.scan(fn [tup], acc -> [tup | acc] end)
			|> Signal.register(name)
		#sig
		#|> Signal.liftapp(fn x -> "Returntrip signal #{name} has a new value: #{inspect x}" end)
		#|> Signal.print
		:ok
	end
end

##############
# EXPERIMENT #
##############

{:ok, file} = File.open("res.txt", [:append])

Registry.set_guarantee(guarantee)

exp_handle = Subject.create
exp_handle
|> Signal.from_plain_obs
|> Signal.register(:exp)
Subject.next(exp_handle, :idle)

paramslist
|> Enum.each(
	fn ps ->
		1..sample_size
		|> Enum.each(
			fn sample ->
				g = GraphCreation.generateGraph(ps)
				cs = CommandsGeneration.generateCommandsDelay(g, ps)
				cs
				|> Enum.each(fn c -> IO.puts(inspect c) end)
				cs
				|> CommandsInterpretation.interpretCommandsDelay({var, prop, fake_mean2, fake_mean3, fake_mean4, final})

				Subject.next(exp_handle, :running)
				IO.puts("EXPERIMENT STARTED")
				:timer.sleep(Keyword.get(ps, :experiment_length))
				Subject.next(exp_handle, :idle)
				IO.puts("EXPERIMENT ENDED")
				:timer.sleep(5000)
				IO.puts("GATHERING & PROCESSING RESULTS")

				IO.write(file, Keyword.get(ps, :name) <> " (#{inspect(sample)}) \n")

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
								|> Enum.filter(fn {_xt, xrs} -> Enum.count(xrs) >= Enum.count(fs) end)
							IO.puts(inspect(full))
							maxes = 
								full
								|> Enum.map(fn {xt, xrs} -> {xt, Enum.max(xrs)} end)
							IO.puts(inspect(maxes))
							delays = 
								maxes
								|> Enum.map(fn {xt, max} -> max - xt end)
							IO.puts(inspect(delays))
							IO.write(file, inspect(delays) <> "\n")
							delays
						end)
					|> List.flatten
				mean = Enum.sum(means) / Enum.count(means)
				IO.puts("Mean total propagation delay: #{mean}")
				IO.write(file, "Mean total propagation delay: #{mean} \n \n")
				IO.puts("SHUTTING DOWN")
				Subject.next(exp_handle, :done)
				:timer.sleep(10000)
				Subject.next(exp_handle, :idle)
			end)
		IO.write(file, "------------------------------------------------------- \n")
	end)

File.close(file)
