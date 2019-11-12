defmodule Reactivity.DSL.DoneNotifier do
  @moduledoc false
  require Logger
  use GenServer
  alias ReactiveMiddleware.Registry

  ####################
  # CLIENT INTERFACE #
  ####################

  @doc """
	Start the GenServer.
	"""
	def start_link(name, options \\ []) do
		GenServer.start_link(__MODULE__, name, options)
	end

	def start(name, options \\ []) do
		GenServer.start(__MODULE__, name, options)
	end

	def stop(notifier) do
		GenServer.cast(notifier, :force_stop)
	end
  
	####################
	# SERVER CALLBACKS #
	####################

	def init(name) do
		{:ok, name}
	end

	def handle_cast({:dependency_stopping, _obs}, name) do
		Registry.remove_signal(name)
		{:stop, :normal, name}
	end

	def handle_cast(:force_stop, name) do
		{:stop, :normal, name}
	end

end