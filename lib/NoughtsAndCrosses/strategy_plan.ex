defmodule NoughtsAndCrosses.StrategyPlan do
  # TODO:
  # * Ensure that the strategy is applied to all four rotations of the board
  # * Then flip the board horizontally and also apply the strategy to the four rotations of that
  # * Then remove any duplicates (keep the first example of each)
  defmacro strategy(_as_string, "when the board represents:", board, _move) do
    # IO.puts board
    board
  end
end