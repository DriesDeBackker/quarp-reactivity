defmodule Reactivity.Quality.Context do
	alias Observables.Obs
	require Logger

	def combine(_, nil), do: nil

	@doc """
	combines a list of contexts in the case of enforcing time synchronization
	Takes a mixed list of tuples {oldest_timestamp, newest_timestamp} and timestamps ti
	Returns a tuple containing the oldest, respectively the most recent timestamp in the list.
	[{tl1,th1}, t2, t3, {t4l, t4h}, ... , {tln,thn}] -> {tl_min, tl_max}
	"""
	def combine(contexts, {:t, _}), do: combine(contexts, :t)
	def combine(contexts, :t) do
		lows = contexts |> Stream.map(fn 
			{low, _high} -> low
			time 				-> time 
		end)
		highs = contexts |> Stream.map(fn
			{_low, high} -> high
			time 				-> time
		end)
		{low, high} = {Enum.min(lows), Enum.max(highs)}
		if (low == high), do: low, else: {low, high}
	end

	@doc """
	combines a list of contexts in the case of enforcing glitch freedom
	[[{s11,{c1low, c1high}},...,{s1n, c1n}], ... , [{sm1,cm1},...,{smn,cmn}]]-> [{sa, ca}, {sb,cb}, ...]
	Joins the list of contexts into one context of tuples {sender, counter}
	and removes duplicate tuples
	"""
	def combine(contexts, {:g, _}), do: combine(contexts, :g)
	def combine(contexts, :g) do
		contexts 
		|> List.flatten
		|> Enum.group_by(&(elem(&1,0)))
		|> Map.values
		|> Enum.map(fn 
			[h | []] -> h
			slst 		 -> 
				lows = slst |> Stream.map(fn 
					{_, {low, _}} -> low
					{_, counter}  -> counter
				end)
				highs = slst |> Stream.map(fn 
					{_, {_, high}} -> high
					{_, counter} 	 -> counter 
				end)
				s = slst |> List.first |> elem(0)
				{low, high} = {Enum.min(lows), Enum.max(highs)}
				c = if (low == high), do: low, else: {low, high}
				{s, c}
			end)
	end

	@doc """
	Decides whether a given context is acceptable under given consistency guarantee.
	"""
	def sufficient_quality?(_, nil), do: true
	def sufficient_quality?(context, {cgt, cgm}) do
		penalty(context, cgt) <= cgm
	end

	@doc """
	Calculates the penalty of a context under the given guarantee
	"""
	defp penalty(context, {:g, _}), do: penalty(context, :g)
	defp penalty(context, :g) do
		context
		|> Stream.map(fn 
				{_s, {low, high}} 	-> high-low
				{_s, _counter} 			-> 0
			end)
		|> Enum.max
	end
	defp penalty(context, {:t, _}), do: penalty(context, :t)
	defp penalty({low, high}, :t), do: high-low
	defp penalty(_time, :t), do: 0


	@doc """
	Creates an observable carrying the contexts for the given guarantee at the rate of the given observalbe.
	"""
	def new_context_obs(obs, nil) do
		Obs.count(obs, 0)
		|> Obs.map(fn _ -> nil end)
	end
	def new_context_obs(obs, {:g, _}), do: new_context_obs(obs, :g)
	def new_context_obs(obs, :g) do
		{_f, pid} = obs
		Obs.count(obs, 0)
		|> Obs.map(fn n -> [{{node(), pid}, n-1}] end)
	end
	def new_context_obs(obs, {:t, _}), do: new_context_obs(obs, :t)
	def new_context_obs(obs, :t) do
		Obs.count(obs, 0)
		|> Obs.map(fn n ->  n-1 end)
	end

end