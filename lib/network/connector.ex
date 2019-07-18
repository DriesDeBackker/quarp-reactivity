defmodule Network.Connector do
	use GenServer
	require Logger

	@port 6666
	@multicast {224, 0, 0, 225}
	@cookie :blabla

	#######
	# API #
	#######

	# Start the server. Called by the app.
	def start_link(_arg) do
  	GenServer.start_link(__MODULE__, [], name: __MODULE__)
	end

	# Initializes this nodes network connections automatically.
	# - Registers the Registry and Evaluator globally
	# - Calls the announce function
	# Actually a helper function but can be called manually as well.
	def initialize() do
		Logger.warn("Initializing the Connector")
    register()
    {:ok, s} = open_multicast(@port, @multicast)
    announce()
    {:ok, s}
	end

	# Registers the Registry and Evaluator globally
	defp register() do
		Logger.warn("Registering the registry and evaluator globally under #{Node.self}")
    :global.register_name({Node.self, :registry}, Process.whereis(Reactivity.Registry))
    :global.register_name({Node.self, :evaluator}, Process.whereis(Network.Evaluator))
	end

	# Opens a multicast socket that listens to incoming announcements of new nodes.
	def open_multicast(port, addr) do
		Logger.warn("Opening a multicast socket")
		:gen_udp.open(port, [
			:binary,
			#Put the following line in comments on a Windows machine.
			#{:ip, addr},
			{:reuseaddr, true},
			{:multicast_ttl, 4},
    	{:multicast_loop, true},
    	{:broadcast, true},
    	{:add_membership, {addr, {0, 0, 0, 0}}},
    	{:active, true}
		])
	end

	# Announces our presence on the network by broadcasting this node's name.
	def announce() do
  	Logger.warn("Announcing our presence on the network")
  	{:ok, sender} = :gen_udp.open(0, mode: :binary)
  	:ok = :gen_udp.send(sender, @multicast, @port, "#{Node.self()}")
	end

	# Function for manually connecting and subscribing to a given list of nodes 
	def manual_connect_and_subscribe(ns) do
		GenServer.call(__MODULE__, {:connect_and_subscribe, ns})
	end

	#############
	# GENSERVER #
	#############

	def init([]) do
		GenServer.cast(__MODULE__, {:initialize})
		{:ok, nil}
	end

	# Handles the initial request for initialization
	# Loops until this node has a fully qualified name (as a result of being networked)
	# Then calls the initialize helper function to handle the details.
	def handle_cast({:initialize}, nil) do
		if Node.self == :nonode@nohost do
			#Logger.warn("FQN not materialized yet!")
			:timer.sleep(500)
			#Logger.warn("Trying again!")
			GenServer.cast(__MODULE__, {:initialize})
			{:noreply, nil}
		else
			Node.set_cookie(@cookie)
			{:ok, s} = initialize()
			{:noreply, s}
		end
	end

	# Handles an incoming announcement that is broadcasted by a new node.
	def handle_info({:udp, _clientSocket, _clientIp, _clientPort, msg}, s) do
  	name = String.to_atom(msg)
  	if name != Node.self do
  		Logger.warn("New node has announced itself: #{name}")
  		connect_and_subscribe(name)
  	end
  	{:noreply, s}
	end

	# Handles the call for manually connecting and subscribing.
	def handle_call({:connect_and_subscribe, ns}, _from, s) do
		ns
		|> Enum.each(fn n -> connect_and_subscribe(n) end)
		{:reply, :ok, s}
	end

	###########
	# HELPERS #
	###########

	# Connects with a node given by its name
	defp connect_and_subscribe(name) do
		Logger.warn("Connecting to #{name}")
  	Node.connect(name)
  	Logger.warn("We are now connected to: #{inspect Node.list}")
  	Logger.warn("Syncing...")
  	:global.sync()
  	hostregistry = :global.whereis_name({name, :registry})
  	Logger.warn("Subscribing #{inspect hostregistry} registry of new node to our registry")
  	Reactivity.Registry.subscribe(hostregistry)
  	Logger.warn("Subscribing our registry to the registry of the new node")
  	GenServer.call(hostregistry, {:subscribe, Process.whereis(Reactivity.Registry)})
	end

end