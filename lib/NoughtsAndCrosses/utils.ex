defmodule NoughtsAndCrosses.Utils do
  def display_board(%{"board" => [[c00, c01, c02], [c10, c11, c12], [c20, c21, c22]]}) do
    IO.puts "Current board"
    IO.puts "#{format_cell(c00)}|#{format_cell(c01)}|#{format_cell(c02)}"
    IO.puts "-+-+-"
    IO.puts "#{format_cell(c10)}|#{format_cell(c11)}|#{format_cell(c12)}"
    IO.puts "-+-+-"
    IO.puts "#{format_cell(c20)}|#{format_cell(c21)}|#{format_cell(c22)}"
  end

  defp format_cell(""), do: " "
  defp format_cell(mark), do: mark

  def play_move(mark, {row, col}, state) do
    message = %{}
    |> Map.put(:mark, mark)
    |> Map.put(:space, [row, col])
    |> Poison.encode!

    Socket.Web.send!(state.socket, {:text, message})
  end
end