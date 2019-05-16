defmodule QuarpExample do
	alias Observables.Subject
	alias Observables.Obs
	alias Reactivity.Registry
	alias Reactivity.DSL.Signal
	
	require Logger

	#####################
	# DEPLOYMENT SCRIPT #
	#####################

	# In this example we just deploy on two virtual nodes on our local machine,
	# called bob and henk. Henk is the master node running this script.

	# We start up both nodes using:
	# iex --sname bob -S mix
	# iex --sname henk -S mix

	# Globally set the guarantee to strict glitch-freedom.
	Registry.set_guarantee({:g, 0})

	temperature1_app = fn ->
		# Create a handle for the source signal
		t1_handle = Subject.create
		# Create a source signal out of it
		_t1 = t1_handle
		|> Signal.from_plain_obs
		|> Signal.register(:t1)
		# Use the handle to generate new source data
		#  Here, we just generate mock data
		Obs.repeat(fn -> Enum.random(0..35) end)
		|> Obs.each(fn v -> Subject.next(t1_handle, v) end)
		:ok
	end

	# Let's deploy some mock sensors on bob
	#Node.spawn(:bob@MSI, temperature1_app)

	####################
	# REACTIVE PROGRAM #
	####################

	# Globally set the guarantee
	def publish_guarantee do
		Registry.set_guarantee({:g, 0})
	end

	# Deploy these first:

	def temperature1_app do
		# Create a handle for the source signal
		t1_handle = Subject.create
		# Create a source signal out of it
		_t1 = t1_handle
		|> Signal.from_plain_obs
		|> Signal.register(:t1)
		# Use the handle to generate new source data
		#  Here, we just generate mock data
		Obs.repeat(fn -> Enum.random(0..35) end)
		|> Obs.each(fn v -> Subject.next(t1_handle, v) end)
		:ok
	end

	def temperature2_app do
		t2_handle = Subject.create
		_t2 = t2_handle
		|> Signal.from_plain_obs
		|> Signal.register(:t2)
		Obs.repeat(fn -> Enum.random(0..35) end)
		|> Obs.each(fn v -> Subject.next(t2_handle, v) end)
	end

	def humidity1_app do
		h1_handle = Subject.create
		_h1 = h1_handle
		|> Signal.from_plain_obs
		|> Signal.register(:h1)
		Obs.repeat(fn -> Enum.random(0..100) end)
		|> Obs.each(fn v -> Subject.next(h1_handle, v) end)
	end

	def humidity2_app do
		h2_handle = Subject.create
		_h2 = h2_handle
		|> Signal.from_plain_obs
		|> Signal.register(:h2)
		Obs.repeat(fn -> Enum.random(0..100) end)
		|> Obs.each(fn v -> Subject.next(h2_handle, v) end)
	end

	def weight12_app do
		w12_handle = Subject.create
		_w12 = w12_handle
		|> Signal.from_plain_obs
		|> Signal.register(:w12)
		Obs.repeat(
			fn -> 
				w1 = Enum.random(0..100) / 100
				w2 = 1 - w1
				{w1, w2}
			end)
		|> Obs.each(fn v -> Subject.next(w12_handle, v) end)
	end

	def wind_app do
		wind_handle = Subject.create
		_wind = wind_handle
		|> Signal.from_plain_obs
		|> Signal.register(:wind)
		Obs.repeat(fn -> Enum.random(0..50) end)
		|> Obs.each(fn v -> Subject.next(wind_handle, v) end)
	end

	# Now deploy these:

	def avgt_app do
		[Signal.signal(:t1), Signal.signal(:t2), Signal.signal(:w12)]
		|> Signal.liftapp(fn x, y, {w1, w2} -> x*w1 + y*w2 end)
		|> Signal.register(:avgt)
	end

	def avgh_app do
		[Signal.signal(:h1), Signal.signal(:h2), Signal.signal(:w12)]
		|> Signal.liftapp(fn x, y, {w1, w2} -> x*w1 + y*w2 end)
		|> Signal.register(:avgh)
	end

	# Finally, deploy these:
	def window_app do
		Signal.signal(:avgt)
		|> Signal.liftapp(fn t -> t < 19 end)
		|> Signal.each(
			fn closed? ->
				if closed? do
					# close the window
				end
			end)
	end

	def feels_like do
		[Signal.signal(:avgt), Signal.signal(:avgh), Signal.signal(:wind)]
		|> Signal.liftapp(fn t, h, w -> apparent_temperature(t, h, w) end)
		|> Signal.register(:feelslike)
	end

	# Helper
	defp apparent_temperature(t, h, w) do
		e = (h / 100) * 6.105 * :math.exp((17.27*t) / (237.7 + t))
		at = t + 0.348 * e - 0.70 * w - 4.25
	end

end