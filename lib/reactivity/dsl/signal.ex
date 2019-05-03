defmodule Reactivity.DSL.Signal do
	alias Reactivity.Quality.Context
	alias Reactivity.Registry
	alias Observables.Obs

  require Logger

	@doc """
	Creates a signal from a plain observable, operating under the globally set consistency guarantee.
	"""
	def from_plain_obs(obs) do
		cg = Registry.get_guarantee
		Logger.debug("The guarantee set: #{inspect cg}")
		cobs = Context.new_context_obs(obs, cg)
		sobs = obs
		|> Obs.zip(cobs)
		{:signal, sobs}
	end

	@doc """
	Creates a signal from a signal observable, that is: an observable with output of the format {v, c}.
	This is used to create signals for guarantees with non-obvious context content that can be manually attached
	using the plain observable interface.
	"""
	def from_signal_obs(sobs) do
		{:signal, sobs}
	end

	@doc """
	Transforms a signal into a plain observable.
	"""
	def to_plain_obs({:signal, sobs}) do
		{vobs, _cobs} = sobs
		|> Obs.unzip
		vobs
	end

	@doc """
  Applies a given procedure to a signal's value and its previous result. 
  Works in the same way as the Enum.scan function:

  Enum.scan(1..10, fn(x,y) -> x + y end) 
  => [1, 3, 6, 10, 15, 21, 28, 36, 45, 55]
  """
	def scan({:signal, sobs}, func, default \\ nil) do
		{vobs, cobs} = sobs
		|> Obs.unzip
		svobs = vobs
		|> Obs.scan(func, default)
		nobs = svobs
		|> Obs.zip(cobs)
		{:signal, nobs}
	end

	@doc """
	Applies a procedure to the values of a signal without changing them.
	Generally used for side effects.
	"""
	def each({:signal, sobs}, proc) do
		{vobs, _cobs} = sobs
		|> Obs.unzip
		vobs
		|> Obs.each(proc)
		{:signal, sobs}
	end

	@doc """
	Lifts and applies a primitive function to one or more signals
	Values of the input signals are produced into output using this function
	depending on the consistency guarantees of the signals
	"""

	def liftapp({:signal, sobs}, func) do
		new_sobs = sobs
		|> Obs.map(fn {v, c} -> {func.(v), c} end)
		{:signal, new_sobs}
	end
	def liftapp(signals, func) do
		# Combine the input from the list of signals
		cg = Registry.get_guarantee
		new_sobs = signals
		|> Enum.map(fn {:signal, sobs} -> sobs end)
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
				vals = clist
				|> Enum.map(fn {v, _c} -> v end)
				cts = clist
				|> Enum.map(fn {_v, c} -> c end)
				new_cxt = Context.combine(cts, cg)
				new_val = apply(func, vals)
				{new_val, new_cxt}
			end)
		{:signal, new_sobs}
	end

  @doc """
  Gets a signal from the registry by its name.
  """
  def signal(name) do
    {:ok, signal} = Registry.get_signal(name)
    signal
  end

  @doc """
  Publishes a signal by registering it in the registry.
  """
	def register(signal, name) do
		Registry.add_signal(signal, name)
    signal
	end

  @doc """
  Unregisters a signal from the registry by its name.
  """
  def unregister(name) do
    Registry.remove_signal(name)
  end

	@doc """
	Inspects the given signal by printing its output values to the console.
	"""
	def print({:signal, obs}) do
		obs
		|> Obs.inspect
		{:signal, obs}
	end

end