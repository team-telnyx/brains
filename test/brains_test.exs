defmodule BrainsTest do
  use ExUnit.Case
  doctest Brains

  test "greets the world" do
    assert Brains.hello() == :world
  end
end
