defmodule BattleBotClient do
  defp hex_digest(string) do
    :crypto.hash(:sha256, string)
    |> Base.encode16
  end
  
  defp login_hash(passcode, salt) do
    (passcode <> salt)
    |> hex_digest
    |> String.downcase
  end
  
  defp login(state) do
    message = %{}
    |> Map.put(:bot_id, state.bot_id)
    |> Map.put(:game, state.game)
    |> Map.put(:login_hash, login_hash(state.bot_passphrase, state.salt))
    |> add_contest(state)
    |> Poison.encode!

    Socket.Web.send!(state.socket, {:text, message})
    
    # Return state so we can chain
    state
  end
  
  defp add_contest(login_creds, %{contest: contest}) do
    Map.put(login_creds, :contest, contest)
  end
  
  defp add_contest(login_creds, _) do
    login_creds
  end
  
  defp game_creds(game, bot_id) do
    Application.fetch_env!(:battle_bot_client, :games)
    |> Map.get(game)
    |> Map.get(bot_id)
    |> Map.put(:game, to_string(game))
  end

  def play_game(game, bot_id) do
    game_creds(game, bot_id)
    |> start_game
    :fin
  end
  
  def play_contest(game, bot_id, contest_name) do
    game_state = game_creds(game, bot_id)
    |> Map.put(:contest, contest_name)
    case start_game(game_state) do
      :ok ->
        play_contest(game, bot_id, contest_name)
      :error ->
        IO.puts("Ending contest loop")
        :fin
    end
  end
  
  def start_game(state) do
    socket = Socket.Web.connect!(state.url, secure: true)
    state
    |> Map.put(:socket, socket)
    |> Map.put(:turn_function, lookup_turn_function(state))
    |> Map.put(:display_function, lookup_display_function(state))
    |> game_loop
  end
  
  defp lookup_turn_function(%{game: "noughtsandcrosses"}) do
    &NoughtsAndCrosses.Bot.handle_turn/2
  end
  
  defp lookup_display_function(%{game: "noughtsandcrosses"}) do
    &NoughtsAndCrosses.Utils.display_board/1
  end
  
  defp handle_message(message, state) do
    message
    |> Poison.decode!
    |> process_message(state)
  end
  
  defp process_message(%{"salt" => salt}, connection_state) do
    IO.puts "Attempting authentication"

    connection_state
    |> Map.put(:salt, salt)
    |> login
    |> Map.put(:turn, 1)
    |> game_loop
  end
  
  defp process_message(%{"authentication" => "OK"}, connection_state) do
    IO.puts "Authentication succeeded"
    connection_state
  end
  
  defp process_message(%{"authentication" => _}, connection_state) do
    IO.puts "Authentication Failed"
    connection_state
  end
  
  defp process_message(%{"state" => game_state}, connection_state) do
    process_message(game_state, connection_state)
  end
  
  defp process_message(game_state = %{"complete" => true, "victor" => victor, "reason" => reason}, connection_state) do
    IO.puts "The game has ended after #{connection_state.turn - 1} #{turn_word(connection_state.turn - 1)}:"
    case {victor, reason} do
      {:nil, _} ->
        IO.puts "  The game was a draw."
      {_, "complete"} ->
        IO.puts "  #{victor} has won the game."
      {_, _} ->
        IO.puts "  #{victor} has won the game due to #{reason}"
    end
    connection_state.display_function.(game_state)
    connection_state
  end

  defp process_message(game_state = %{"complete" => false, "nextPlayer" => next_player}, connection_state) do
    IO.puts "Turn ##{connection_state.turn} - #{next_player} to play"
    connection_state.display_function.(game_state)
    connection_state.turn_function.(game_state, connection_state)
    connection_state
    |> Map.put(:turn, connection_state.turn + 1)
  end
  
  defp process_message(message, connection_state) do
    IO.puts "Received unknown message = #{inspect message}"
    connection_state
  end

  defp turn_word(1), do: "turn"
  defp turn_word(_), do: "turns"

  defp game_loop(:ok), do: :ok
  defp game_loop(:error), do: :error
  defp game_loop(state) do
    case Socket.Web.recv!(state.socket) do
      {:text, message} ->
        game_loop(handle_message(message, state))
      {:ping, _ } ->
        state.socket |> Socket.Web.send!({:pong, ""})
        game_loop(state)
      {:close, :normal, _} ->
        :ok
      {:close, :abnormal, _} ->
        :error
    end
  end
end
