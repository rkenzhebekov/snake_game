defmodule ElixirSnake.Scene.Game do
  use Scenic.Scene
  alias Scenic.Graph
  # alias Scenic.ViewPort
  import Scenic.Primitives, only: [text: 3, rrect: 3]

  @graph Graph.build(font: :roboto, font_size: 36)
  @tile_size 23
  @tile_radius 8
  @snake_starting_size 5
  @frame_ms 192
  @pellet_score 100

  @input_classes [:codepoint, :key]

  # @left {-1, 0}
  # @right {1, 0}
  # @up {0, -1}
  # @down {0, 1}

  def init(scene, _param, _opts) do
    {width, height} = scene.viewport.size
    vp_tile_width = trunc(width / @tile_size)
    vp_tile_height = trunc(height / @tile_size)

    snake_start_coords = {
      trunc(vp_tile_width / 2),
      trunc(vp_tile_height / 2)
    }

    pellet_start_coords = {
      vp_tile_width - 2,
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
          snake: %{body: [snake_start_coords], size: @snake_starting_size, direction: {1, 0}},
          pellet: pellet_start_coords
        },
        had_input: false
      )

    graph =
      @graph
      |> draw_score(scene.assigns.score)
      |> draw_game_objects(scene.assigns.objects)

    scene = push_graph(scene, graph)

    :ok = request_input(scene, @input_classes)

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

  defp draw_object(graph, :pellet, {pellet_x, pellet_y}) do
    draw_tile(graph, pellet_x, pellet_y, fill: :yellow, id: :pellet)
  end

  defp draw_tile(graph, x, y, opts) do
    tile_opts = Keyword.merge([fill: :white, translate: {x * @tile_size, y * @tile_size}], opts)

    graph
    |> rrect({@tile_size, @tile_size, @tile_radius}, tile_opts)
  end

  def handle_info(:frame, %Scenic.Scene{assigns: state} = scene) do
    # IO.inspect(state)
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

    state
    |> put_in([:objects, :snake, :body], new_body)
    |> maybe_eat_pallet(new_head_pos)
    |> maybe_die()
    |> put_in([:had_input], false)
  end

  defp move(%{tile_width: w, tile_height: h}, {pos_x, pos_y}, {vec_x, vec_y}) do
    {rem(pos_x + vec_x + w, w), rem(pos_y + vec_y + h, h)}
  end

  defp maybe_die(%{} = state) do
    state
  end

  defp maybe_eat_pallet(%{objects: %{pellet: pellet_coords}} = state, snake_head_coords)
       when pellet_coords == snake_head_coords do
    state
    |> randomize_pellet()
    |> add_score(@pellet_score)
    |> grow_snake()
  end

  defp maybe_eat_pallet(state, _), do: state

  defp randomize_pellet(%{tile_width: w, tile_height: h} = state) do
    pellet_coords = {
      Enum.random(0..(w - 1)),
      Enum.random(0..(h - 1))
    }

    validate_pellet_coords(state, pellet_coords)
  end

  defp validate_pellet_coords(%{objects: %{snake: %{body: snake}}} = state, coords) do
    if coords in snake do
      randomize_pellet(state)
    else
      put_in(state, [:objects, :pellet], coords)
    end
  end

  defp add_score(state, amount) do
    update_in(state, [:score], &(&1 + amount))
  end

  defp grow_snake(state) do
    update_in(state, [:objects, :snake, :size], &(&1 + 1))
  end

  def handle_input({:key, _}, _context, %Scenic.Scene{assigns: %{had_input: true}} = scene) do
    {:noreply, scene}
  end

  def handle_input({:key, {:key_left, _, _}}, _context, %Scenic.Scene{assigns: state} = scene) do
    IO.inspect(state)
    state = update_snake_direction(state, {-1, 0})
    scene = assign(scene, Enum.to_list(state))
    {:noreply, scene}
  end

  def handle_input({:key, {:key_right, _, _}}, _context, %Scenic.Scene{assigns: state} = scene) do
    IO.inspect(state)
    state = update_snake_direction(state, {1, 0})
    scene = assign(scene, Enum.to_list(state))
    {:noreply, scene}
  end

  def handle_input({:key, {:key_up, _, _}}, _context, %Scenic.Scene{assigns: state} = scene) do
    IO.inspect(state)
    state = update_snake_direction(state, {0, -1})
    scene = assign(scene, Enum.to_list(state))
    {:noreply, scene}
  end

  def handle_input({:key, {:key_down, _, _}}, _context, %Scenic.Scene{assigns: state} = scene) do
    IO.inspect(state)
    state = update_snake_direction(state, {0, 1})
    scene = assign(scene, Enum.to_list(state))
    {:noreply, scene}
  end

  def handle_input(evt, _ctx, scene) do
    IO.inspect(evt, label: "Input")
    {:noreply, scene}
  end

  defp update_snake_direction(state, direction) do
    {old_x, old_y} = state.objects.snake.direction

    if direction in [{-old_x, 0}, {0, -old_y}] do
      state
    else
      put_in(state, [:objects, :snake, :direction], direction)
      |> put_in([:had_input], true)
    end
  end
end
