defmodule GenTest do
  use ExUnit.Case
  doctest Gen

  test "main" do
    Gen.main
  end
end
