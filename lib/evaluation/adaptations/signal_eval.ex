defmodule Evaluation.Adaptations.SignalEval do
  @moduledoc false
	alias Reactivity.Quality.Context
	alias ReactiveMiddleware.Registry
	alias Observables.Obs
	alias Evaluation.Adaptations.CombineLatestNEval
	alias Observables.GenObservable

	def liftapp_eval(signals, func) do
		# Combine the input from the list of signals
		cg = Registry.get_guarantee
		new_sobs = 
			signals
			|> Enum.map(fn {:signal, sobs} -> sobs end)
			|> combinelatest_n_eval
			# Filter out input that is not of sufficient quality.
			|> Obs.filter(
				fn {ctup, val} ->
					Tuple.to_list(ctup)
					|> Enum.map(fn {_v, c} -> c end)
					|> Context.combine(cg)
					|> Context.sufficient_quality?(cg)
			end)
			# Apply the function to the input to create output.
			|> Obs.map(
				fn {ctup, {eval, ecxt}} -> 
					clist = Tuple.to_list(ctup)
					vals = 
						clist
						|> Enum.map(fn {v, _c} -> v end)
					cts = 
						clist
						|> Enum.map(fn {_v, c} -> c end)
					new_cxt = Context.combine(cts, cg)
					_new_val = apply(func, vals)
					{eval, new_cxt}
				end)
		{:signal, new_sobs}
	end


defp combinelatest_n_eval(obss, opts \\ [inits: nil]) do
    inds = 0..(length(obss)-1)
    #Create list of nils as initial values when no initial values given as option.
    inits = Keyword.get(opts, :inits)
    inits = 
      if inits == nil do
        inds |> Enum.map(fn _ -> nil end)
      else
        inits
      end

    # We tag each value from an observee with its respective index
    tagged = Enum.zip(obss, inds)
      |> Enum.map(fn {obs, index} -> obs
        #|> Observables.Obs.inspect()
        |> Obs.map(fn v -> {index, v} end) end)

    # Start our CombineLatestNEval observable.
    {:ok, pid} = GenObservable.start(CombineLatestNEval, [inits])

    # Make the observees send to us.
    tagged |> Enum.each(fn {obs_f, _obs_pid} -> obs_f.(pid) end)

    # Create the continuation.
    {fn observer ->
       GenObservable.send_to(pid, observer)
     end, pid}
  end

end