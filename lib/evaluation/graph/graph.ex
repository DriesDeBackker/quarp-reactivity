defmodule Evaluation.Graph do
  @moduledoc false
	alias Evaluation.Graph

	defstruct hosts: [], vars: [], signals: [], hostedAt: %{}, deps: %{} 

	def new(hosts) do
		%Graph{hosts: hosts}
	end

	def getHosts(%Graph{hosts: cs}) do
		cs
	end

	def addVar(graph=%Graph{vars: vs, hostedAt: ha}, var, host) do
		new_vs = [var | vs]
		new_ha = Map.put(ha, var, host)
		%{graph | vars: new_vs, hostedAt: new_ha}
	end

	def getVars(%Graph{vars: vs}) do
		vs
	end

	def getSignalLevels(%Graph{signals: ss}) do
		ss
	end

	def getNodes(%Graph{vars: vs, signals: ss}) do
		vs ++ List.flatten(ss)
	end

	def getDeps(%Graph{deps: deps}, n) do
		Map.get(deps, n)
	end

	def addSignal(graph=%Graph{signals: ss, hostedAt: ha, deps: dss}, signal, host, ds) do
		l = 
			(ds
			|> Enum.map(fn d -> getLevel(graph, d) end)
			|> Enum.max) + 1
		new_ss = 
			cond do
				l > Enum.count(ss) + 1 
					-> ss ++ [[signal]]
				true 
					-> List.replace_at(ss, l-2, [signal | Enum.at(ss, l-2)])
			end
		new_ha = Map.put(ha, signal, host)
		new_dss = Map.put(dss, signal, ds)
		%{graph | hostedAt: new_ha, signals: new_ss, deps: new_dss}
	end

	def getHost(%Graph{hostedAt: ha}, n) when is_atom(n) do
		Map.get(ha, n)
	end

	def getLevel(%Graph{vars: vs, signals: ss}, n) when is_atom(n) do
		if Enum.any?(vs, fn v -> v == n end) do
			1
		else
			getLevelHelper(ss, 2, n)
		end
	end

	defp getLevelHelper([], _l, _n) do
		raise "node not part of graph!"
	end
	defp getLevelHelper([ln | lt], l, n) do
		if Enum.any?(ln, fn s -> s == n end) do
			l
		else
			getLevelHelper(lt, l+1, n)
		end
	end

	def getNodesAtLevel(%Graph{vars: vs}, 1), do: vs
	def getNodesAtLevel(%Graph{signals: ss}, l) when is_integer(l) and l > 1 do
		Enum.at(ss, l-2)
	end

	def getNumberOfLevels(%Graph{signals: ss}) do
		Enum.count(ss) + 1
	end

	def getFinalNodesForVar(g=%Graph{}, var) do
		tc = getTransitiveClosure(g, var)
		fs = getFinalNodes(g)
		tc -- (tc -- fs)
	end

	def getTransitiveClosure(g=%Graph{}, n) do
		closure = [n]
		l = getLevel(g, n)
		if l == getNumberOfLevels(g) do
			closure
		else
			getTransitiveClosure(g, l+1, closure)
		end
	end
	def getTransitiveClosure(g=%Graph{deps: ds}, l, closure) do
		candidates = getNodesAtLevel(g, l)
		cand_deps = 
			candidates
			|> Enum.map(fn c -> Map.get(ds, c) end)
		new_closure = 
			candidates
			|> Enum.zip(cand_deps)
			|> Enum.filter(
				fn {_c, deps} -> 
					uniq_concat = 
						closure
						|> Enum.concat(deps)
						|> Enum.uniq
					Enum.count(uniq_concat) < Enum.count(closure) + Enum.count(deps)
				end)
			|> Enum.map(fn {c, _deps} -> c end)
			|> Enum.concat(closure)
		if l == getNumberOfLevels(g) do
			new_closure
		else
			getTransitiveClosure(g, l+1, new_closure)
		end
	end

	def getFinalNodes(g=%Graph{deps: dss}) do
		deps = 
			dss
			|> Map.values
			|> List.flatten
			|> Enum.uniq
		getNodes(g)
		|> Enum.filter(fn n -> not Enum.any?(deps, fn x -> x == n end) end)
	end
end