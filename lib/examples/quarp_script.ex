defmodule QuarpScript do
	alias Observables.Subject
	alias Observables.Obs
	alias Reactivity.Registry
	alias Reactivity.DSL.Signal
	import Deployment
	
	require Logger

	#####################
	# DEPLOYMENT SCRIPT #
	#####################

	# In this example we just deploy on two virtual nodes on our local machine,
	# called bob and henk. Henk is the master node running this script.

	# We start up both nodes using:
	# iex --sname bob -S mix
	# iex --sname henk -S mix
	# Note that you have to change ports in the connector file for this to work.
	def run do
		bob = :bob@MSI

		yes = fn ->
			IO.puts("YES")
		end

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

		# Let's deploy 'yes' at bob.
		#deploy(bob, yes)
		# Let's deploy a mock temperature sensor on bob.
		deploy(bob, yes)

	end
	
end