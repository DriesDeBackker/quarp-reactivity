defmodule Evaluation.Commands.CommandsInterpretation do
  @moduledoc false
	import ReactiveMiddleware.Deployer

	def interpretCommandsDelay([], _fns), do: :ok
	def interpretCommandsDelay([c | cst], {var, un, bin, tern, quat, final}=fns) do
		case c do
			{:var, v, h, im, isd} -> deploy(h, var.(v, im, isd))
			{:signal, s, h, [d1]} -> deploy(h, un.(s, d1))
			{:signal, s, h, [d1, d2]} -> deploy(h, bin.(s, d1, d2))
			{:signal, s, h, [d1, d2, d3]} -> deploy(h, tern.(s, d1, d2, d3))
			{:signal, s, h, [d1, d2, d3, d4]} -> deploy(h, quat.(s, d1, d2, d3, d4))
			{:final, v, f, h} -> deploy(h, final.(v, f))
		end
		:timer.sleep(250)
		interpretCommandsDelay(cst, fns)
	end

	def interpretCommandsTraffic([], _fns), do: :ok
	def interpretCommandsTraffic([c | cst], {var, un, bin, tern, quat}=fns) do
		case c do
			{:var, v, h, im, isd, vm, vsd} -> deploy(h, var.(v, im, isd, vm, vsd))
			{:signal, s, h, [d1]} -> deploy(h, un.(s, d1))
			{:signal, s, h, [d1, d2]} -> deploy(h, bin.(s, d1, d2))
			{:signal, s, h, [d1, d2, d3]} -> deploy(h, tern.(s, d1, d2, d3))
			{:signal, s, h, [d1, d2, d3, d4]} -> deploy(h, quat.(s, d1, d2, d3, d4))
		end
		:timer.sleep(250)
		interpretCommandsTraffic(cst, fns)
	end
end