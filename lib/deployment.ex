defmodule Deployment do

	def deploy(snode, program) do
		evaluator = :global.whereis_name({snode, :evaluator})
		GenServer.call(evaluator, {:deploy_program, program})
	end
end