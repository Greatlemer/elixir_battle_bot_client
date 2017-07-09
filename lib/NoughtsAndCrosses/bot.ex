defmodule NoughtsAndCrosses.Bot do
  def handle_turn(game_state = %{"complete" => false}, state = %{bot_id: my_id}) do
    case Map.get(game_state, "nextPlayer") do
      ^my_id ->
        case Map.get(game_state, "marks") do
          %{"X" => ^my_id} ->
            handle_turn(Map.get(game_state, "board"), "X", state)
          %{"O" => ^my_id} ->
            handle_turn(Map.get(game_state, "board"), "O", state)
        end
      _ ->
        :nil
    end
    state
  end

  def handle_turn(board, mark, state) do
    move = deduce_move(
      board,
      mark,
      [
        :complete_line,
        :block_line,
        :turn_two_safety,
        :turn_three_safety,
        :turn_three_killer,
        :turn_three_side_advantage,
        :turn_three_corner_advantage,
        :turn_four_safety,
        :turn_five_killer,
        :random_space
      ])
    NoughtsAndCrosses.Utils.play_move(mark, move, state)
  end

  defp deduce_move(board, mark, [strategy |strategies]) do
    case deduce_move(board, mark, strategy) do
      {:yes, coords} ->
        coords
      :no ->
        deduce_move(board, mark, strategies)
    end
  end

  defp deduce_move(board, mark, :complete_line) do
    complete_three(board, mark)
  end

  defp deduce_move(board, mark, :block_line) do
    complete_three(board, other_mark(mark))
  end

  defp deduce_move(board, mark, :turn_two_safety) do
    turn_two_safety(board, other_mark(mark))
  end

  defp deduce_move(board, mark, :turn_three_safety) do
    turn_three_safety(board, mark, other_mark(mark))
  end

  defp deduce_move(board, mark, :turn_three_killer) do
    turn_three_killer(board, mark, other_mark(mark))
  end

  defp deduce_move(board, mark, :turn_three_side_advantage) do
    turn_three_side_advantage(board, mark, other_mark(mark))
  end

  defp deduce_move(board, mark, :turn_three_corner_advantage) do
    turn_three_corner_advantage(board, mark, other_mark(mark))
  end

  defp deduce_move(board, mark, :turn_four_safety) do
    turn_four_safety(board, mark, other_mark(mark))
  end

  defp deduce_move(board, mark, :turn_five_killer) do
    turn_five_killer(board, mark, other_mark(mark))
  end

  defp deduce_move(board, _, :random_space) do
    random_move(board)
  end

  defp other_mark("X"), do: "O"
  defp other_mark("O"), do: "X"
 
  # If they start and play on a side, drop one on an adjacent corner to prevent later tragedy
  defp turn_two_safety([["", other, ""], ["", "", ""], ["", "", ""]], other), do: {:yes, {0, 2}}
  defp turn_two_safety([["", "", ""], [other, "", ""], ["", "", ""]], other), do: {:yes, {2, 0}}
  defp turn_two_safety([["", "", ""], ["", "", other], ["", "", ""]], other), do: {:yes, {0, 2}}
  defp turn_two_safety([["", "", ""], ["", "", ""], ["", other, ""]], other), do: {:yes, {2, 0}}
  defp turn_two_safety(_board, _other), do: :no

  # If you start in the center and they go to a side you can force a win by playing one of the opposing corners
  defp turn_three_killer([["", other, ""], ["", mark, ""], ["", "", ""]], mark, other), do: {:yes, {2, 0}}
  defp turn_three_killer([["", "", ""], [other, mark, ""], ["", "", ""]], mark, other), do: {:yes, {0, 2}}
  defp turn_three_killer([["", "", ""], ["", mark, other], ["", "", ""]], mark, other), do: {:yes, {2, 0}}
  defp turn_three_killer([["", "", ""], ["", mark, ""], ["", other, ""]], mark, other), do: {:yes, {0, 2}}

  # If you start in a corner and they go to a side or 'adjacent corner' you can force a win
  defp turn_three_killer([[mark, other, ""], ["", "", ""], ["", "", ""]], mark, other), do: {:yes, {2, 0}}
  defp turn_three_killer([[mark, "", ""], [other, "", ""], ["", "", ""]], mark, other), do: {:yes, {0, 2}}
  defp turn_three_killer([[mark, "", other], ["", "", ""], ["", "", ""]], mark, other), do: {:yes, {2, 2}}
  defp turn_three_killer([[mark, "", ""], ["", "", ""], [other, "", ""]], mark, other), do: {:yes, {2, 2}}

  defp turn_three_killer([["", other, mark], ["", "", ""], ["", "", ""]], mark, other), do: {:yes, {2, 2}}
  defp turn_three_killer([["", "", mark], ["", "", other], ["", "", ""]], mark, other), do: {:yes, {0, 0}}
  defp turn_three_killer([[other, "", mark], ["", "", ""], ["", "", ""]], mark, other), do: {:yes, {2, 0}}
  defp turn_three_killer([["", "", mark], ["", "", ""], ["", "", other]], mark, other), do: {:yes, {2, 0}}

  defp turn_three_killer([["", "", ""], ["", "", ""], [mark, other, ""]], mark, other), do: {:yes, {2, 0}}
  defp turn_three_killer([["", "", ""], [other, "", ""], [mark, "", ""]], mark, other), do: {:yes, {2, 2}}
  defp turn_three_killer([["", "", ""], ["", "", ""], [mark, "", other]], mark, other), do: {:yes, {0, 2}}
  defp turn_three_killer([[other, "", ""], ["", "", ""], [mark, "", ""]], mark, other), do: {:yes, {0, 2}}

  defp turn_three_killer([["", "", ""], ["", "", ""], ["", other, mark]], mark, other), do: {:yes, {0, 2}}
  defp turn_three_killer([["", "", ""], ["", "", other], ["", "", mark]], mark, other), do: {:yes, {2, 0}}
  defp turn_three_killer([["", "", ""], ["", "", ""], [other, "", mark]], mark, other), do: {:yes, {0, 0}}
  defp turn_three_killer([["", "", other], ["", "", ""], ["", "", mark]], mark, other), do: {:yes, {0, 0}}
  defp turn_three_killer(_board, _mark, _other), do: :no
  
  defp turn_three_safety([["", mark, other], ["", "", ""], ["", "", ""]], mark, other), do: {:yes, {2, 0}}
  defp turn_three_safety([[other, mark, ""], ["", "", ""], ["", "", ""]], mark, other), do: {:yes, {2, 2}}
  defp turn_three_safety([["", "", other], ["", "", mark], ["", "", ""]], mark, other), do: {:yes, {2, 0}}
  defp turn_three_safety([["", "", ""], ["", "", mark], ["", "", other]], mark, other), do: {:yes, {0, 0}}
  defp turn_three_safety([[other, "", ""], [mark, "", ""], ["", "", ""]], mark, other), do: {:yes, {2, 2}}
  defp turn_three_safety([["", "", ""], [mark, "", ""], [other, "", ""]], mark, other), do: {:yes, {0, 2}}
  defp turn_three_safety([["", "", ""], ["", "", ""], ["", mark, other]], mark, other), do: {:yes, {0, 0}}
  defp turn_three_safety([["", "", ""], ["", "", ""], [other, mark, ""]], mark, other), do: {:yes, {0, 2}}
  
  # Not sure this makes a difference now but will leave just in case.
  defp turn_three_safety([[mark, "", ""], ["", other, ""], ["", "", ""]], mark, other), do: {:yes, {0, 2}}
  defp turn_three_safety([["", "", mark], ["", other, ""], ["", "", ""]], mark, other), do: {:yes, {0, 0}}
  defp turn_three_safety([["", "", ""], ["", other, ""], [mark, "", ""]], mark, other), do: {:yes, {0, 0}}
  defp turn_three_safety([["", "", ""], ["", other, ""], ["", "", mark]], mark, other), do: {:yes, {0, 2}}
  defp turn_three_safety(_board, _mark, _other), do: :no
  
  defp turn_four_safety([[mark, "", ""], ["", other, ""], ["", "", mark]], mark, other), do: {:yes, {1, 2}}
  defp turn_four_safety([["", "", mark], ["", other, ""], [mark, "", ""]], mark, other), do: {:yes, {1, 2}}
  defp turn_four_safety(_board, _mark, _other), do: :no

  # We can maximise chances of winning at turn three when we started in a corner and they play the center
  defp turn_three_corner_advantage([[mark, "", ""], ["", other, ""], ["", "", ""]], mark, other), do: {:yes, {2, 2}}
  defp turn_three_corner_advantage([["", "", mark], ["", other, ""], ["", "", ""]], mark, other), do: {:yes, {2, 0}}
  defp turn_three_corner_advantage([["", "", ""], ["", other, ""], [mark, "", ""]], mark, other), do: {:yes, {0, 2}}
  defp turn_three_corner_advantage([["", "", ""], ["", other, ""], ["", "", mark]], mark, other), do: {:yes, {0, 0}}
  defp turn_three_corner_advantage(_board, _mark, _other), do: :no

  # We can maximise chances of winning at turn three when we started on the side and they play the center
  defp turn_three_side_advantage([["", mark, ""], ["", "", ""], ["", "", other]], mark, other), do: {:yes, {2, 0}}
  defp turn_three_side_advantage([["", mark, ""], ["", "", ""], [other, "", ""]], mark, other), do: {:yes, {2, 2}}
  defp turn_three_side_advantage([["", "", other], [mark, "", ""], ["", "", ""]], mark, other), do: {:yes, {2, 2}}
  defp turn_three_side_advantage([["", "", ""], [mark, "", ""], ["", "", other]], mark, other), do: {:yes, {0, 2}}
  defp turn_three_side_advantage([[other, "", ""], ["", "", mark], ["", "", ""]], mark, other), do: {:yes, {2, 0}}
  defp turn_three_side_advantage([["", "", ""], ["", "", mark], [other, "", ""]], mark, other), do: {:yes, {0, 0}}
  defp turn_three_side_advantage([[other, "", ""], ["", "", ""], ["", mark, ""]], mark, other), do: {:yes, {0, 2}}
  defp turn_three_side_advantage([["", "", other], ["", "", ""], ["", mark, ""]], mark, other), do: {:yes, {0, 0}}
  defp turn_three_side_advantage(_board, _mark, _other), do: :no

  # We can finsih them off after the side advantage if they do the wrong thing next
  defp turn_five_killer([["", mark, ""], ["", "", ""], [mark, other, other]], mark, other), do: {:yes, {0, 0}}
  defp turn_five_killer([["", mark, ""], ["", "", ""], [other, other, mark]], mark, other), do: {:yes, {0, 2}}
  defp turn_five_killer([["", "", other], [mark, "", other], ["", "", mark]], mark, other), do: {:yes, {2, 0}}
  defp turn_five_killer([["", "", mark], [mark, "", other], ["", "", other]], mark, other), do: {:yes, {0, 0}}
  defp turn_five_killer([[other, "", ""], [other, "", mark], [mark, "", ""]], mark, other), do: {:yes, {2, 2}}
  defp turn_five_killer([[mark, "", ""], [other, "", mark], [other, "", ""]], mark, other), do: {:yes, {0, 2}}
  defp turn_five_killer([[other, other, mark], ["", "", ""], ["", mark, ""]], mark, other), do: {:yes, {2, 2}}
  defp turn_five_killer([[mark, other, other], ["", "", ""], ["", mark, ""]], mark, other), do: {:yes, {2, 0}}
  defp turn_five_killer(_board, _mark, _other), do: :no

  # Complete rows
  defp complete_three([["", mark, mark], _, _], mark), do: {:yes, {0,0}}
  defp complete_three([[mark, "", mark], _, _], mark), do: {:yes, {0,1}}
  defp complete_three([[mark, mark, ""], _, _], mark), do: {:yes, {0,2}}
  defp complete_three([_, ["", mark, mark], _], mark), do: {:yes, {1,0}}
  defp complete_three([_, [mark, "", mark], _], mark), do: {:yes, {1,1}}
  defp complete_three([_, [mark, mark, ""], _], mark), do: {:yes, {1,2}}
  defp complete_three([_, _, ["", mark, mark]], mark), do: {:yes, {2,0}}
  defp complete_three([_, _, [mark, "", mark]], mark), do: {:yes, {2,1}}
  defp complete_three([_, _, [mark, mark, ""]], mark), do: {:yes, {2,2}}

  # Complete cols
  defp complete_three([["", _, _], [mark, _, _], [mark, _, _]], mark), do: {:yes, {0,0}}
  defp complete_three([[mark, _, _], ["", _, _], [mark, _, _]], mark), do: {:yes, {1,0}}
  defp complete_three([[mark, _, _], [mark, _, _], ["", _, _]], mark), do: {:yes, {2,0}}
  defp complete_three([[_, "", _], [_, mark, _], [_, mark, _]], mark), do: {:yes, {0,1}}
  defp complete_three([[_, mark, _], [_, "", _], [_, mark, _]], mark), do: {:yes, {1,1}}
  defp complete_three([[_, mark, _], [_, mark, _], [_, "", _]], mark), do: {:yes, {2,1}}
  defp complete_three([[_, _, ""], [_, _, mark], [_, _, mark]], mark), do: {:yes, {0,2}}
  defp complete_three([[_, _, mark], [_, _, ""], [_, _, mark]], mark), do: {:yes, {1,2}}
  defp complete_three([[_, _, mark], [_, _, mark], [_, _, ""]], mark), do: {:yes, {2,2}}

  # Complete diags
  defp complete_three([["", _, _], [_,mark, _], [ _, _, mark]], mark), do: {:yes, {0,0}}
  defp complete_three([[mark, _, _], [_, "", _], [_, _, mark]], mark), do: {:yes, {1,1}}
  defp complete_three([[mark, _, _], [_, mark, _], [_, _, ""]], mark), do: {:yes, {2,2}}
  defp complete_three([[_, _, ""], [_, mark, _], [mark, _, _]], mark), do: {:yes, {0,2}}
  defp complete_three([[_, _, mark], [_, "", _], [mark, _, _]], mark), do: {:yes, {1,1}}
  defp complete_three([[_, _, mark], [_, mark, _], ["", _, _]], mark), do: {:yes, {2,0}}

  # Nothing to complete
  defp complete_three(_board, _mark), do: :no

  defp random_move(board = [["", "", ""], ["", "", ""], ["", "", ""]]) do
    first_empty(board, Enum.shuffle(1..9))
  end

  defp random_move(board) do
    first_empty(board, [5] ++ Enum.shuffle([1,3,7,9]) ++ Enum.shuffle([2,4,6,8]))
  end
    
  defp first_empty(board, [position | tail]) do
    case is_empty(board, position) do
      move = {:yes, _} ->
        move
      :no ->
        first_empty(board, tail)
    end
  end
    
  defp is_empty([["", _, _], _, _], 1), do: {:yes, {0, 0}}
  defp is_empty([[_, "", _], _, _], 2), do: {:yes, {0, 1}}
  defp is_empty([[_, _, ""], _, _], 3), do: {:yes, {0, 2}}
  defp is_empty([_, ["", _, _], _], 4), do: {:yes, {1, 0}}
  defp is_empty([_, [_, "", _], _], 5), do: {:yes, {1, 1}}
  defp is_empty([_, [_, _, ""], _], 6), do: {:yes, {1, 2}}
  defp is_empty([_, _, ["", _, _]], 7), do: {:yes, {2, 0}}
  defp is_empty([_, _, [_, "", _]], 8), do: {:yes, {2, 1}}
  defp is_empty([_, _, [_, _, ""]], 9), do: {:yes, {2, 2}}
  defp is_empty(_board, _row), do: :no
end