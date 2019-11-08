defmodule Evaluation.Commands.CommandsGeneration do
  @moduledoc false
	alias Evaluation.Graph

	def generateCommandsDelay(g, params) do
		[]
		|> generateVarCommandsDelay(g, params)
		|> generateSignalCommands(g)
		|> generateFinalCommands(g)
		|> Enum.reverse
	end

	def generateCommandsTraffic(g, params) do
		[]
		|> generateVarCommandsTraffic(g, params)
		|> generateSignalCommands(g)
		|> Enum.reverse
	end

	defp generateVarCommandsTraffic(cs, g, params) do
		generateVarCommandsTraffic(cs, Graph.getVars(g), g, params)
	end
	defp generateVarCommandsTraffic(cs, [], _g, _params), do: cs
	defp generateVarCommandsTraffic(cs, [v | vst], g, params) do
		h 	= Graph.getHost(g, v)
		im  = Keyword.get(params, :update_interval_mean)
		isd = Keyword.get(params, :update_interval_sd)
		vm  = Keyword.get(params, :values_mean)
		vsd = Keyword.get(params, :values_sd)
		new_c = {:var, v, h, im, isd, vm, vsd}
		generateVarCommandsTraffic([new_c | cs], vst, g, params)
	end

	defp generateVarCommandsDelay(cs, g, params) do
		generateVarCommandsDelay(cs, Graph.getVars(g), g, params)
	end
	defp generateVarCommandsDelay(cs, [], _g, _params), do: cs
	defp generateVarCommandsDelay(cs, [v | vst], g, params) do
		h 	= Graph.getHost(g, v)
		im  = Keyword.get(params, :update_interval_mean)
		isd = Keyword.get(params, :update_interval_sd)
		new_c = {:var, v, h, im, isd}
		generateVarCommandsDelay([new_c | cs], vst, g, params)
	end

	defp generateSignalCommands(cs, g) do
		generateSignalCommands(cs, Graph.getSignalLevels(g), g)
	end
	defp generateSignalCommands(cs, [], _g), do: cs
	defp generateSignalCommands(cs, [[] | sst], g), do: generateSignalCommands(cs, sst, g)
	defp generateSignalCommands(cs, [[s | st] | sst], g) do
		h = Graph.getHost(g, s)
		deps = Graph.getDeps(g, s)
		new_c = {:signal, s, h, deps}
		generateSignalCommands([new_c | cs], [st | sst], g)
	end


	defp generateFinalCommands(cs, g) do
		vars = Graph.getVars(g) -- Graph.getFinalNodes(g)
		finals = Enum.map(vars, fn v -> Graph.getFinalNodesForVar(g, v) end)
		finals_for_vars = Enum.zip(vars, finals)
		generateFinalCommands(cs, finals_for_vars, g)
	end
	defp generateFinalCommands(cs, [], _g), do: cs
	defp generateFinalCommands(cs, [{_var, []} | ffvst], g) do
		generateFinalCommands(cs, ffvst, g)
	end
	defp generateFinalCommands(cs, [{var, [f | ft]} | ffvst], g) do
		h = Graph.getHost(g, var)
		new_c = {:final, var, f, h}
		generateFinalCommands([new_c | cs], [{var, ft} | ffvst], g)
	end

end