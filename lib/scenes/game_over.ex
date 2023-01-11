defmodule ElixirSnake.Scene.GameOver do
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [text: 3, update_opts: 2]

  @text_opts [id: :gameover, fill: :white, text_align: :center]

  @graph Graph.build(font: :roboto, font_size: 36, clear_color: :black)
         |> text("Game Over!", @text_opts)

  @game_scene ElixirSnake.Scene.Game

  def init(scene, score, _opts) do
    {vp_width, vp_height} = scene.viewport.size
    position = {vp_width / 2, vp_height / 2}

    graph =
      @graph
      |> Graph.modify(:gameover, &update_opts(&1, translate: position))

    scene = push_graph(scene, graph)

    scene =
      assign(scene,
        viewport: scene.viewport,
        score: score,
        graph: graph
      )

    Process.send_after(self(), :end_cooldown, 2000)

    {:ok, scene}
  end

  def handle_info(:end_cooldown, scene) do
    state = scene.assigns

    graph =
      state.graph
      |> Graph.modify(
        :gameover,
        &text(
          &1,
          "Game Over!\n You scored #{state.score}.\n Press any key to try again.",
          @text_opts
        )
      )

    scene = push_graph(scene, graph)

    :ok = request_input(scene, [:key])

    {:noreply, scene}
  end

  def handle_input({:key, _}, _context, scene) do
    restart_game(scene.assigns)
    {:noreply, scene}
  end

  def handle_input(_input, _context, scene) do
    {:noreply, scene}
  end

  defp restart_game(%{viewport: vp}) do
    ViewPort.set_root(vp, @game_scene, nil)
  end
end
