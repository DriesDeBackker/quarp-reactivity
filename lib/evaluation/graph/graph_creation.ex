defmodule Evaluation.Graph.GraphCreation do
  @moduledoc false
	alias Evaluation.Graph

	def generateGraph(params) do
		Graph.new(Keyword.get(params, :hosts))
		|> generateVars(Keyword.get(params, :nb_of_vars))
		|> generateSignalLevels(params)
	end

	defp generateVars(g, 0), do: g
	defp generateVars(g, n) when is_integer(n) and n > 0 do
		hosts = Graph.getHosts(g)
		host = Enum.at(hosts, :rand.uniform(Enum.count(hosts))-1)
		new_v = String.to_atom("var" <> Integer.to_string(n))
		new_g = Graph.addVar(g, new_v, host)
		generateVars(new_g, n-1)
	end

	defp generateSignalLevels(g, params) do
		l = Keyword.get(params, :graph_depth)
		generateSignalLevels(g, params, l)
	end
	defp generateSignalLevels(g, _params, 1), do: g
	defp generateSignalLevels(g, params, k) when is_integer(k) and k > 1 do
		n_avg = Keyword.get(params, :signals_per_level_avg)
		n_act = :rand.uniform(2*n_avg - 1)
		l = Keyword.get(params, :graph_depth) - k + 2
		ss = generateSignals(g, params, l, n_act, [])
		new_g = addSignals(g, ss)
		generateSignalLevels(new_g, params, k-1)
	end

	defp generateSignals(_g, _params, _l, 0, ss), do: ss
	defp generateSignals(g, params, l, n, ss) do
		n_deps_avg = Keyword.get(params, :deps_per_signal_avg)
		n_deps_act = 
			case n_deps_avg do
				1 -> 1
				2 -> :rand.uniform(3)
				3 -> :rand.uniform(3) + 1
				_ -> raise "deps_per_signal_avg set too high! Locality parameter not independent anymore."
			end
		new_sig = String.to_atom("sig" <> Integer.to_string(l) <> Integer.to_string(n))
		deps = chooseDeps(g, l, n_deps_act, [])
		host = chooseHost(g, params, deps)
		generateSignals(g, params, l, n-1, [{new_sig, {host, deps}} | ss])
	end

	defp chooseDeps(_g, _l, 0, deps), do: deps
	defp chooseDeps(g, l, n, []) do
		pool = Graph.getNodesAtLevel(g, l-1)
		dep = Enum.at(pool, :rand.uniform(Enum.count(pool))-1)
		chooseDeps(g, l, n-1, [dep])
	end
	defp chooseDeps(g, l, n, deps) do
		pool = Graph.getNodes(g) -- deps
		dep = Enum.at(pool, :rand.uniform(Enum.count(pool))-1)
		chooseDeps(g, l, n-1, [dep | deps])
	end

	defp chooseHost(g, params, deps) do
		locality = Keyword.get(params, :nodes_locality)
		localHosts =
			deps
			|> Enum.map(fn d -> Graph.getHost(g, d) end)
			|> Enum.uniq
		remoteHosts = Graph.getHosts(g) -- localHosts
		r = :rand.uniform
		hostPool = 
			cond do
				r >  locality -> localHosts
				r <= locality -> remoteHosts
			end
		Enum.at(hostPool, :rand.uniform(Enum.count(hostPool))-1)
	end


	defp addSignals(g, []), do: g
	defp addSignals(g, [{sig, {host, deps}} | ss]) do
		g_new = Graph.addSignal(g, sig, host, deps)
		addSignals(g_new, ss)
	end

end