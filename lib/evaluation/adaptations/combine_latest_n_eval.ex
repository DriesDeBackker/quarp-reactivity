defmodule Evaluation.Adaptations.CombineLatestNEval do
  @moduledoc false
  use Observables.GenObservable
  require Logger

  def init([initials]) do
    Logger.debug("CombineLatestNEval: #{inspect(self())}")
    {:ok, initials}
  end

  def handle_event({index, value}, state) do
  	new_state = state |> List.replace_at(index, value)
  	if Enum.any?(new_state, fn x -> x == nil end) do
  		{:novalue, new_state}
  	else
  		{:value, {List.to_tuple(new_state), value}, new_state}
  	end
  end

  def handle_done(_pid, _state) do
    Logger.debug("#{inspect(self())}: CombineLatestNEval has one dead dependency, going on.")
    {:ok, :continue}
  end

end