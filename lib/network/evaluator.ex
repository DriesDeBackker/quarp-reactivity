defmodule Network.Evaluator do
  use GenServer
  require Logger
  alias GenServer

  ####################
  # Client interface #
  ####################

  @doc """
  Start the GenServer.
  """
  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Deploys a program locally in the reactor.
  """
  def deploy_program(program) do
    GenServer.cast(__MODULE__, {:deploy_program, program})
  end

  ####################
  # Server callbacks #
  ####################

  def init([]) do
    {:ok, %{}}
  end

  def handle_call({:deploy_program, program}, _from, state) do
    res = program.()

    Logger.debug("""
    Program evaluated
    ======================================
    Result of evaluation: #{inspect(res)}
    ======================================
    """)

    {:reply, :ok, state}
  end
end
