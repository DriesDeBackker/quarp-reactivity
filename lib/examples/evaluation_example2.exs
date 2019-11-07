alias Observables.Subject
alias Observables.Obs
alias ReactiveMiddleware.Registry
alias Reactivity.DSL.Signal
import Deployment

require Logger

#####################
# DEPLOYMENT SCRIPT #
#####################

# In this evaluation example we deploy a minimal distributed reactive application
# to 4 Raspberry Pi nodes.
# Specifically, we deploy a mock sensor to a source node whose signal
# two other nodes are subscribed to. These nodes then send their messages
# back to the first node, who combines them and measures the round-trip time.
# Strict glitch-freedom, {:g, 0}, is enforced.
# One of the two intermediate nodes delays its messages by a time `td`.
# The sampling interval is set to `is`.

# Activate the program as follows:
# - Start the QUARP middleware and spawn an iex shell
#   iex --name bob@pc -S mix
#   (If not automatically connected with the rpis, connect manually:
#   Network.Connector.manual_connect_and_subscribe([rpi1, rpi2, rpi3]))
# - Load this script:
#   import_file("path/to/this_script.exs")

# The fully qualified names of the rpi nodes:
rpi1= :"nerves@192.168.1.4"
rpi2= :"nerves@192.168.1.5"
rpi3= :"nerves@192.168.1.3"

# Globally set the guarantee to strict glitch-freedom.
Registry.set_guarantee({:g, 0})

si = 100
n = 5000

####################
# REACTIVE PROGRAM #
####################

mock_sensor = fn ->
	ss_handle = Subject.create
	ss = ss_handle
	|> Signal.from_plain_obs
	|> Signal.register(:ss)
	Obs.repeat(fn -> :erlang.monotonic_time end, [interval: si, times: n])
	|> Obs.each(fn v -> Subject.next(ss_handle, v) end)
	:ok
end

#start_mock_data = fn ->
# Obs.repeat(fn -> :erlang.monotonic_time end, [interval: si, times: n])
#|> Obs.each(fn v -> Subject.next(ss_handle, v) end)
#	:ok
#end

deploy(rpi1, mock_sensor)

######################################

intermediate1 = fn ->
	Signal.signal(:ss)
	|> Signal.liftapp(fn x -> x end)
	|> Signal.register(:s1)
	|> Signal.print
	:ok
end

deploy(rpi2, intermediate1)

intermediate2 = fn ->
	Signal.signal(:ss)
	|> Signal.register(:s2)
	|> Signal.print
	:ok
end

deploy(rpi3, intermediate2)

######################################

round_trip = fn ->
	results = 
		[Signal.signal(:s1), Signal.signal(:s2)]
		|> Signal.liftapp(fn x, y -> if x == y, do: x, else: nil end)
		|> Signal.liftapp(fn x -> [(:erlang.monotonic_time - x) / 1000] end)
		|> Signal.scan(fn x, l -> l ++ x end)
	mean = 
		results
		|> Signal.liftapp(fn l -> Enum.sum(l)/length(l) end)
	variance =
		[results, mean]
		|> Signal.liftapp(
			fn rs, m -> 
				s = rs
				|> Stream.map(fn r -> :math.pow(r-m, 2) end)
				|> Enum.sum
				s/length(rs)
			end)
	:ok
	min_max =
		results
		|> Signal.liftapp(fn l -> {Enum.min(l), Enum.max(l)} end)

	mean
	|> Signal.liftapp(fn m -> "Mean: #{inspect m}" end)
	|> Signal.print
	variance
	|> Signal.liftapp(fn v -> "Variance: #{inspect v}" end)
	|> Signal.print
	min_max
	|> Signal.liftapp(fn mm -> "Min, max: #{inspect mm}" end)
	|> Signal.print
end

deploy(rpi1, round_trip)