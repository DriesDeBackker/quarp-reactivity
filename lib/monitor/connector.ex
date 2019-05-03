defmodule Connector do
	use GenServer
	require Logger

	@port2 7777
	@port1 6666
	@multicast {127, 0, 0, 1}

	def start_link(_arg) do
  	GenServer.start_link(__MODULE__, [], name: __MODULE__)
	end

	def init([]) do
		Logger.debug("Registering the registry globally as #{Node.self}")
		:global.register_name(Node.self, Process.whereis(Reactivity.Registry))
		{:ok, s} = :gen_udp.open(@port1, [
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

	defp announce() do
  	Logger.info("Announcing our presence on the network")
  	{:ok, sender} = :gen_udp.open(0, mode: :binary)
  	:ok = :gen_udp.send(sender, @multicast, @port2, "#{Node.self()}")
	end

	def handle_info({:udp, _clientSocket, _clientIp, _clientPort, msg}, socket) do
  	Logger.info("New node has announced itself.")
  	handle_discovery(msg)
  	{:noreply, socket}
	end

	def handle_info({:udp_error, _, _}, socket) do
		Logger.info("failed announcement, to self??")
		{:noreply, socket}
	end

	defp handle_discovery(msg) do
  	hostname = String.to_atom(msg)
  	Node.connect(hostname)
  	Logger.info("disovered #{hostname}")
  	:global.sync()
  	hostregistry = :global.whereis_name(hostname)
  	Reactivity.Registry.subscribe(hostregistry)
  	GenServer.call(hostregistry, {:subscribe, Process.whereis(Reactivity.Registry)})
	end
end