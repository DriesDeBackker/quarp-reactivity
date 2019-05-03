defmodule Test.Quality.ContextTest do
	use ExUnit.Case
	alias Reactivity.Quality.Context

  #@tag :disabled
  test "Combine contexts in case of no guarantee" do
    context1 = nil
    context2 = nil
    contexts = [context1, context2]
    guarantee = nil
    combined_context = Context.combine(contexts, guarantee)
    assert(combined_context == nil)
  end

  #@tag :disabled
  test "Combine single context in case of :t (1)" do
    context = 5
    contexts = [context]
    combined_context = Context.combine(contexts, :t)
    assert(combined_context == 5)
  end

  #@tag :disabled
  test "Combine single context in case of :t (2)" do
    context = {2, 4}
    contexts = [context]
    combined_context = Context.combine(contexts, :t)
    assert(combined_context == {2, 4})
  end

	#@tag :disabled
  test "Combine contexts in case of :t (1)" do
    context1 = 5
    context2 = {2, 4}
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :t)
    assert(combined_context == {2,5})
  end

  #@tag :disabled
  test "Combine contexts in case of :t (2)" do
    context1 = 5
    context2 = 5
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :t)
    assert(combined_context == 5)
  end

  #@tag :disabled
  test "Combine contexts in case of :t (3)" do
    context1 = {1, 3}
    context2 = {2, 4}
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :t)
    assert(combined_context == {1, 4})
  end

  #@tag :disabled
  test "Combine contexts in case of :t (4)" do
    context1 = {1, 3}
    context2 = {2, 4}
    context3 = 5
    contexts = [context1, context2, context3]
    combined_context = Context.combine(contexts, :t)
    assert(combined_context == {1, 5})
  end

  #@tag :disabled
  test "Combine contexts in case of :t (5)" do
    context1 = 3
    context2 = 4
    context3 = 5
    contexts = [context1, context2, context3]
    combined_context = Context.combine(contexts, :t)
    assert(combined_context == {3, 5})
  end

  #@tag :disabled
  test "Combine single context in case of :g (1)" do
    context = [{:s1, 5}]
    contexts = [context]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, 5}])
  end

  #@tag :disabled
  test "Combine single context in case of :g (2)" do
    context = [{:s1, 5}, {:s2, 7}]
    contexts = [context]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, 5}, {:s2, 7}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (1)" do
    context1 = [{:s1, 5}]
    contexts = [context1]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, 5}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (2)" do
    context1 = [{:s1, 5}, {:s2, 7}]
    contexts = [context1]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, 5}, {:s2, 7}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (3)" do
    context1 = [{:s1, 5}]
    context2 = [{:s2, 7}]
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, 5}, {:s2, 7}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (4)" do
    context1 = [{:s1, 5}]
    context2 = [{:s1, 5}, {:s2, 7}]
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, 5}, {:s2, 7}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (5)" do
    context1 = [{:s1, 5}]
    context2 = [{:s1, 3}, {:s2, 7}]
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, {3, 5}}, {:s2, 7}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (6)" do
    context1 = [{:s1, {3, 5}}]
    context2 = [{:s1, 2}, {:s2, 7}]
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, {2, 5}}, {:s2, 7}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (7)" do
    context1 = [{:s1, {3, 5}}, {:s2, 4}]
    context2 = [{:s1, 2}, {:s2, 7}]
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, {2, 5}}, {:s2, {4, 7}}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (8)" do
    context1 = [{:s1, {3, 5}}, {:s2, 4}]
    context2 = [{:s2, 7}, {:s1, 2}]
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, {2, 5}}, {:s2, {4, 7}}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (9)" do
    context1 = [{:s1, {3, 5}}, {:s2, 4}]
    context2 = [{:s2, 7}, {:s1, 2}]
    context3 = [{:s3, 4}, {:s2, {3, 5}}]
    contexts = [context1, context2, context3]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{:s1, {2, 5}}, {:s2, {3, 7}}, {:s3, 4}])
  end

  #@tag :disabled
  test "Combine contexts in case of :g (10)" do
    context1 = [{{:bob@MSI, :temperature1}, {3, 5}}, {{:bob@MSI, :temperature2}, 4}]
    context2 = [{{:bob@MSI, :temperature2}, 7}, {{:bob@MSI, :temperature1}, 2}]
    contexts = [context1, context2]
    combined_context = Context.combine(contexts, :g)
    assert(combined_context == [{{:bob@MSI, :temperature1}, {2, 5}}, {{:bob@MSI, :temperature2}, {4, 7}}])
  end

	####################################################

  #@tag :disabled
  test "Sufficient quality in case of no guarantee" do
    context1 = nil
    context2 = nil
    contexts = [context1, context2]
    guarantee = nil
    combined_context = Context.combine(contexts, guarantee)
    assert(Context.sufficient_quality?(combined_context, guarantee))
  end

  #@tag :disabled
  test "Sufficient quality in case of :t (1)" do
    context1 = 5
    context2 = 5
    contexts = [context1, context2]
    guarantee = {:t, 0}
    combined_context = Context.combine(contexts, guarantee)
    assert(Context.sufficient_quality?(combined_context, guarantee))
  end

  #@tag :disabled
  test "Sufficient quality in case of :t (2)" do
    context1 = 5
    context2 = 4
    contexts = [context1, context2]
    guarantee = {:t, 0}
    combined_context = Context.combine(contexts, guarantee)
    assert(not Context.sufficient_quality?(combined_context, guarantee))
  end

  #@tag :disabled
  test "Sufficient quality in case of :t (3)" do
    context1 = 5
    context2 = 6
    contexts = [context1, context2]
    guarantee = {:t, 1}
    combined_context = Context.combine(contexts, guarantee)
    assert(Context.sufficient_quality?(combined_context, guarantee))
  end

  #@tag :disabled
  test "Sufficient quality in case of :t (4)" do
    context1 = {5, 7}
    context2 = 5
    contexts = [context1, context2]
    guarantee = {:t, 1}
    combined_context = Context.combine(contexts, guarantee)
    assert(not Context.sufficient_quality?(combined_context, guarantee))
  end

  #@tag :disabled
  test "Sufficient quality in case of :t (5)" do
    context1 = {5, 7}
    context2 = {4, 5}
    contexts = [context1, context2]
    guarantee = {:t, 2}
    combined_context = Context.combine(contexts, guarantee)
    assert(not Context.sufficient_quality?(combined_context, guarantee))
  end

  #@tag :disabled
  test "Sufficient quality in case of :t (6)" do
    context1 = {5, 6}
    context2 = {4, 5}
    contexts = [context1, context2]
    guarantee = {:t, 2}
    combined_context = Context.combine(contexts, guarantee)
    assert(Context.sufficient_quality?(combined_context, guarantee))
  end

  #@tag :disabled
  test "Sufficient quality in case of :g (1)" do
    context1 = [{:s1, {3, 5}}, {:s2, 5}]
    context2 = [{:s2, 7}, {:s1, 3}]
    contexts = [context1, context2]
    guarantee = {:g, 2}
    combined_context = Context.combine(contexts, guarantee)
    assert(Context.sufficient_quality?(combined_context, guarantee))
  end

  #@tag :disabled
  test "Sufficient quality in case of :g (2)" do
    context1 = [{:s1, {3, 5}}, {:s2, 4}]
    context2 = [{:s2, 7}, {:s1, 3}]
    contexts = [context1, context2]
    guarantee = {:g, 1}
    combined_context = Context.combine(contexts, guarantee)
    assert(not Context.sufficient_quality?(combined_context, guarantee))
  end

  #@tag :disabled
  test "Sufficient quality in case of :g (3)" do
    context1 = [{:s1, 5}, {:s2, 4}]
    context2 = [{:s3, 7}]
    contexts = [context1, context2]
    guarantee = {:g, 0}
    combined_context = Context.combine(contexts, guarantee)
    assert(Context.sufficient_quality?(combined_context, guarantee))
  end

  #@tag :disabled
  test "Sufficient quality in case of :g (4)" do
    context1 = [{:s1, 5}, {:s2, 7}]
    context2 = [{:s2, 7}]
    contexts = [context1, context2]
    guarantee = {:g, 0}
    combined_context = Context.combine(contexts, guarantee)
    assert(Context.sufficient_quality?(combined_context, guarantee))
  end

  #@tag :disabled
  test "Sufficient quality in case of :g (5)" do
    context1 = [{:s1, 5}, {:s2, 7}]
    context2 = [{:s2, 7}]
    context3 = [{:s1, 4}]
    contexts = [context1, context2, context3]
    guarantee = {:g, 0}
    combined_context = Context.combine(contexts, guarantee)
    assert(not Context.sufficient_quality?(combined_context, guarantee))
  end

end