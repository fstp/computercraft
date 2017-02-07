defmodule Gen do
  def main do
    File.read!("blueprint.txt")
    |> String.split("\n", trim: true)
    |> create_layers(%{layers: []})
    |> trace
  end

  def create_layers([head | tail], state) do
    {_x,y} = parse_dimensions(head)
    {rows, tail} = Enum.split(tail, y)
    create_layers(tail, %{state | layers: [parse_layer(rows) | state.layers]})
  end
  def create_layers([], state) do
    %{state | layers: Enum.reverse(state.layers)}
  end

  def parse_layer(rows) do
    rows
    |> Enum.reverse
    |> Enum.zip(1..100000)
    |> Enum.map(&parse_row/1)
  end

  def parse_row(row) do
    row
  end

  def parse_dimensions(line) do
    [x,y] = String.split(line, ",")
    {x,""} = Integer.parse(x)
    {y,""} = Integer.parse(y)
    {x,y}
  end

  def trace(args) when is_binary(args) do
    IO.puts args
    args
  end
  def trace(args) do
    IO.inspect args
  end
end
