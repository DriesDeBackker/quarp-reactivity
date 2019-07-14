defmodule Network.Connector do
	use GenServer
	require Logger

	@port 6666
	@multicast {239, 0, 0, 250}

	def start_link(_arg) do
  	GenServer.start_link(__MODULE__, [], name: __MODULE__)
	end

	def init([]) do
		Logger.debug("Registering the registry globally as #{Node.self}")
		:global.register_name({Node.self, :registry}, Process.whereis(Reactivity.Registry))
		:global.register_name({Node.self, :evaluator}, Process.whereis(Network.Evaluator))
		{:ok, s} = 
			:gen_udp.open(@port, [
				:binary,
				{:reuseaddr, true},
				{:ip, @multicast},
				{:multicast_ttl, 4},
      	{:multicast_loop, true},
      	{:broadcast, true},
      	{:add_membership, {@multicast, {0, 0, 0, 0}}},
      	{:active, true}
			])
  	announce()
  	{:ok, s}
	end

	def announce() do
  	Logger.info("Announcing our presence on the network")
  	{:ok, sender} = :gen_udp.open(0, mode: :binary)
  	:ok = :gen_udp.send(sender, @multicast, @port, "#{Node.self()}")
	end

	def handle_info({:udp, _clientSocket, _clientIp, _clientPort, msg}, socket) do
  	hostname = String.to_atom(msg)
  	if hostname != Node.self do
  		Logger.info("New node has announced itself: #{hostname}")
  		handle_discovery(msg)
  	end
  	{:noreply, socket}
	end

	def handle_info({:udp_error, _, _}, socket) do
		Logger.info("failed announcement, to self??")
		{:noreply, socket}
	end

	defp handle_discovery(hostname) do
  	Node.connect(hostname)
  	:global.sync()
  	hostregistry = :global.whereis_name({hostname, :registry})
  	Reactivity.Registry.subscribe(hostregistry)
  	GenServer.call(hostregistry, {:subscribe, Process.whereis(Reactivity.Registry)})
	end
end