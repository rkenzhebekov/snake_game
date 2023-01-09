defmodule ElixirSnake.Scene.Game do
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives, only: [text: 3, rrect: 3]

  @graph Graph.build(font: :roboto, font_size: 36)
  @tile_size 23
  @tile_radius 8
  @snake_starting_size 5
  @frame_ms 192

  def init(scene, _param, _opts) do
    {width, height} = scene.viewport.size
    vp_tile_width = trunc(width / @tile_size)
    vp_tile_height = trunc(height / @tile_size)

    snake_start_coords = {
      trunc(vp_tile_width / 2),
      trunc(vp_tile_height / 2)
    }

    {:ok, timer} = :timer.send_interval(@frame_ms, :frame)

    scene =
      assign(scene,
        score: 0,
        tile_width: vp_tile_width,
        tile_height: vp_tile_height,
        frame_count: 1,
        frame_timer: timer,
        graph: @graph,
        objects: %{
          snake: %{body: [snake_start_coords], size: @snake_starting_size, direction: {1, 0}}
        }
      )

    graph =
      @graph
      |> draw_score(scene.assigns.score)
      |> draw_game_objects(scene.assigns.objects)

    scene = push_graph(scene, graph)

    {:ok, scene}
  end

  defp draw_score(graph, score) do
    graph
    |> text("Score: #{score}", fill: :white, translate: {@tile_size, @tile_size})
  end

  defp draw_game_objects(graph, object_map) do
    Enum.reduce(object_map, graph, fn {object_type, object_data}, graph ->
      draw_object(graph, object_type, object_data)
    end)
  end

  defp draw_object(graph, :snake, %{body: snake}) do
    Enum.reduce(snake, graph, fn {x, y}, graph ->
      draw_tile(graph, x, y, fill: :lime)
    end)
  end

  defp draw_tile(graph, x, y, opts) do
    tile_opts = Keyword.merge([fill: :white, translate: {x * @tile_size, y * @tile_size}], opts)

    graph
    |> rrect({@tile_size, @tile_size, @tile_radius}, tile_opts)
  end

  def handle_info(:frame, %Scenic.Scene{assigns: state} = scene) do
    IO.inspect(state)
    state = move_snake(state)

    graph =
      @graph
      |> draw_game_objects(state.objects)
      |> draw_score(state.score)

    scene = push_graph(scene, graph)
    state = %{state | frame_count: state.frame_count + 1}
    scene = assign(scene, Enum.to_list(state))

    {:noreply, scene}
  end

  defp move_snake(%{objects: %{snake: snake}} = state) do
    [head | _] = snake.body
    new_head_pos = move(state, head, snake.direction)
    new_body = Enum.take([new_head_pos | snake.body], snake.size)
    put_in(state, [:objects, :snake, :body], new_body)
  end

  defp move(%{tile_width: w, tile_height: h}, {pos_x, pos_y}, {vec_x, vec_y}) do
    {rem(pos_x + vec_x + w, w), rem(pos_y + vec_y + h, h)}
  end
end
