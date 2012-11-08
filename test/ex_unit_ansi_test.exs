Code.require_file "../test_helper.exs", __FILE__

defmodule ExUnitAnsiTest do
  use ExUnit.Case

  test "the truth" do
    assert true
  end

  test "failure" do
    flunk false
  end
end
