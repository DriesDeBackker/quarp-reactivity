defmodule Evaluation.Adaptations.SignalEval do
  @moduledoc false
	alias Reactivity.Quality.Context
	alias ReactiveMiddleware.Registry
	alias Observables.Obs

	def liftapp_eval(signals, func) do
		# Combine the input from the list of signals
		cg = Registry.get_guarantee
		local_sobss = 
			signals
			|> Enum.map(fn {:signal, sobs} -> sobs end)
		eval_vals = 
			local_sobss
			|> Obs.merge
		new_sobs = 
			local_sobss
			|> Obs.combinelatest_n
			# Filter out input that is not of sufficient quality.
			|> Obs.filter(
				fn ctup ->
					Tuple.to_list(ctup)
					|> Enum.map(fn {_v, c} -> c end)
					|> Context.combine(cg)
					|> Context.sufficient_quality?(cg)
			end)
			# Apply the function to the input to create output.
			|> Obs.map(
				fn ctup -> 
					clist = Tuple.to_list(ctup)
					vals = 
						clist
						|> Enum.map(fn {v, _c} -> v end)
					cts = 
						clist
						|> Enum.map(fn {_v, c} -> c end)
					new_cxt = Context.combine(cts, cg)
					new_val = apply(func, vals)
					eval_val = Obs.last(eval_vals)
					{eval_val, new_cxt}
				end)
		{:signal, new_sobs}
	end

end