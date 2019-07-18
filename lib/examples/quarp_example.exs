alias Observables.Subject
alias Observables.Obs
alias Reactivity.Registry
alias Reactivity.DSL.Signal
import Deployment

require Logger

#####################
# DEPLOYMENT SCRIPT #
#####################

# In this example we deploy a simple distributed reactive application
# to a series of Raspberry Pi nodes.
# Specifically, it is the example reactive program from the QUARP paper.
# Mock data simulates sensor measurements.

# Activate the program as follows:
# - Start the QUARP middleware and spawn an iex shell
#   iex --name bob@pc -S mix
#   (If not automatically connected with the rpis, connect manually:
#   Network.Connector.manual_connect_and_subscribe([rpi1, rpi2, rpi3]))
# - Load this script:
#   import_file("path/to/this_script.exs")

# The fully qualified names of the rpi nodes:
rpi1= :"nerves@192.168.1.5"
rpi2= :"nerves@192.168.1.4"
rpi3= :"nerves@192.168.1.3"

# Globally set the guarantee to strict glitch-freedom.
Registry.set_guarantee({:g, 0})

####################
# REACTIVE PROGRAM #
####################

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

deploy(rpi1, temperature1_app)

######################################

temperature2_app = fn ->
	t2_handle = Subject.create
	_t2 = t2_handle
	|> Signal.from_plain_obs
	|> Signal.register(:t2)
	Obs.repeat(fn -> Enum.random(0..35) end)
	|> Obs.each(fn v -> Subject.next(t2_handle, v) end)
end

deploy(rpi2, temperature2_app)

######################################

humidity1_app = fn ->
	h1_handle = Subject.create
	_h1 = h1_handle
	|> Signal.from_plain_obs
	|> Signal.register(:h1)
	Obs.repeat(fn -> Enum.random(0..100) end)
	|> Obs.each(fn v -> Subject.next(h1_handle, v) end)
end

deploy(rpi1, humidity1_app)

######################################

humidity2_app = fn ->
	h2_handle = Subject.create
	_h2 = h2_handle
	|> Signal.from_plain_obs
	|> Signal.register(:h2)
	Obs.repeat(fn -> Enum.random(0..100) end)
	|> Obs.each(fn v -> Subject.next(h2_handle, v) end)
end

deploy(rpi2, humidity2_app)

######################################

weight12_app = fn ->
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

deploy(rpi3, weight12_app)

######################################

wind_app = fn ->
	wind_handle = Subject.create
	_wind = wind_handle
	|> Signal.from_plain_obs
	|> Signal.register(:wind)
	Obs.repeat(fn -> Enum.random(0..50) end)
	|> Obs.each(fn v -> Subject.next(wind_handle, v) end)
end

deploy(rpi3, wind_app)

######################################

avgt_app = fn ->
	[Signal.signal(:t1), Signal.signal(:t2), Signal.signal(:w12)]
	|> Signal.liftapp(fn x, y, {w1, w2} -> x*w1 + y*w2 end)
	|> Signal.register(:avgt)
end

deploy(rpi2, avgt_app)

avgh_app = fn ->
	[Signal.signal(:h1), Signal.signal(:h2), Signal.signal(:w12)]
	|> Signal.liftapp(fn x, y, {w1, w2} -> x*w1 + y*w2 end)
	|> Signal.register(:avgh)
end

deploy(rpi2, avgh_app)

######################################

# Finally, deploy these:
window_app = fn ->
	Signal.signal(:avgt)
	|> Signal.liftapp(fn t -> t < 19 end)
	|> Signal.each(
		fn closed? ->
			if closed? do
				IO.puts("should close")
			end
		end)
end

deploy(rpi3, window_app)

feels_like = fn ->
	[Signal.signal(:avgt), Signal.signal(:avgh), Signal.signal(:wind)]
	|> Signal.liftapp(
		fn t, h, w -> 
			e = (h / 100) * 6.105 * :math.exp((17.27*t) / (237.7 + t))
			at = t + 0.348 * e - 0.70 * w - 4.25 
		end)
	|> Signal.register(:feelslike)
end

deploy(rpi3, feels_like)