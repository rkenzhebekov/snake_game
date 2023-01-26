defmodule ElixirSnake.Scene.PlayGround do
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives

  @graph Graph.build(font: :roboto, font_size: 22, rotate: 0)
         |> text("Hello Muzaffar and Ismael", translate: {100, 50}, rotate: 0.0)
         # |> ellipse({25, 10}, stroke: {1, :yellow}, translate: {300, 120})
         |> circle(50, fill: :white, translate: {300, 200}, id: :head)
         |> quad({{40, 0}, {20, 50}, {90, 50}, {70, 0}},
           fill: :silver,
           translate: {245, 115}
         )
         |> triangle({{300, 190}, {295, 210}, {340, 205}}, fill: :orange, id: :nose)
         |> circle(3, fill: :black, translate: {280, 180}, id: :left_eye)
         |> circle(3, fill: :black, translate: {320, 180}, id: :right_eye)
         |> arc({45, 0.9}, rotate: 1.1, stroke: {2, :black}, translate: {300, 172}, id: :mouth)
         |> circle(80, fill: :white, translate: {300, 300}, id: :body)
         |> line({{223, 280}, {120, 370}}, stroke: {5, :brown}, id: :right_hand)
         |> line({{377, 280}, {480, 370}}, stroke: {5, :brown}, id: :left_hand)
         |> circle(120, fill: :white, translate: {300, 450}, id: :leg)

  def init(scene, _param, _opts) do
    scene = push_graph(scene, @graph)
    {:ok, scene}
  end
end
