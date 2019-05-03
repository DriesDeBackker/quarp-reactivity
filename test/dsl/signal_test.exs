defmodule Test.DSL.SignalTest do
	use ExUnit.Case
	alias Reactivity.DSL.Signal
	alias Reactivity.Registry
	alias Observables.Subject

	test "lifting binary function on two signals from same source under :g" do
		testproc = self

		Registry.set_guarantee({:g, 0})

		obs = Subject.create
		sig1 = obs 
		|> Signal.from_plain_obs
		plus = sig1
		|> Signal.liftapp(fn x -> x + 1 end)
		min = sig1
		|> Signal.liftapp(fn x -> x - 1 end)
		res = [plus, min]
		|> Signal.liftapp(fn x, y -> x + y end)
		|> Signal.each(fn x -> send(testproc, x) end)

		Subject.next(obs, 3)
		assert_receive(6)

		receive do
			x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
		after
			100 -> :ok
		end

		Subject.next(obs, 2)
		assert_receive(4)

		receive do
			x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
		after
			100 -> :ok
		end

	end

	test "lifting binary function on two signals from same source without guarantee" do
		testproc = self

		Registry.set_guarantee(nil)

		obs = Subject.create
		sig1 = obs 
		|> Signal.from_plain_obs
		plus = sig1
		|> Signal.liftapp(fn x -> x + 1 end)
		min = sig1
		|> Signal.liftapp(fn x -> x - 1 end)
		res = [plus, min]
		|> Signal.liftapp(fn x, y -> x + y end)
		|> Signal.each(fn x -> send(testproc, x) end)

		Subject.next(obs, 3)
		assert_receive(6)

		Subject.next(obs, 2)
		assert_receive(x)
		assert_receive(4)

		receive do
			x -> flunk("Mailbox was supposed to be empty, got: #{inspect(x)}")
		after
			100 -> :ok
		end

	end

end