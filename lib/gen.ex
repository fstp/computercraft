defmodule Gen do
  def main do
    File.read!("blueprint.txt")
    |> String.split("\n", trim: true)
    |> create_layers(%{layers: []})
  end

  def create_layers([head | tail], state) do
    {_x,y} = parse_dimensions(head)
    {rows, tail} = Enum.split(tail, y)
    create_layers(tail, %{state | layers: [parse_layer(rows, y) | state.layers]})
  end
  def create_layers([], state) do
    %{state | layers: Enum.reverse(state.layers)}
  end

  def parse_layer(rows, length) do
    rows
    |> Enum.reverse
    |> Enum.zip(1..100000)
    |> Enum.map(fn row -> parse_row(row, length) end)
  end

  def parse_row({data, idx}, length) do
    data
    |> String.split("", trim: true)
    |> align(idx)
    |> add_turn(idx, length)
    |> group
    |> Enum.map(fn group -> to_lua(group, length(group)) end)
    |> trace
  end

  def align(data, idx) do
    case rem(idx, 2) == 0 do
      true -> Enum.reverse(data)
      false -> data
    end
  end

  def add_turn(data, length, length) do
    List.update_at(data, -1, fn _slot -> "H" end)
  end
  def add_turn(data, idx, _length) do
    case rem(idx, 2) == 0 do
      true -> List.update_at(data, -1, fn _slot -> "R" end)
      false -> List.update_at(data, -1, fn _slot -> "L" end)
    end
  end

  def to_lua(["0"], 1) do
    ["dig()\n"]
  end
  def to_lua(["R"], 1) do
    "R"
  end
  def to_lua(["L"], 1) do
    "L"
  end
  def to_lua(["H"], 1) do
    "H"
  end
  def to_lua([slot], 1) when is_binary(slot) do
    ["place(", slot, ")\n"]
  end
  def to_lua(slots, _length) do
    slots
  end

  def lua_fun_turn_around() do
    ["function turnAround()\n",
     "turtle.turnLeft()\n",
     "turtle.turnLeft()\n",
     "end\n"]
  end
  def lua_fun_place() do
    ["function place(slot)\n",
     "turtle.dig()\n",
     "turtle.forward()\n",
     "turnAround()\n",
     "turtle.select(slot)\n",
     "turtle.place()\n",
     "turnAround()\n",
     "end\n"]
  end
  def lua_fun_dig() do
    ["function dig()\n",
     "turtle.dig()\n",
     "turtle.forward()\n",
     "end\n"]
  end

  def group(items) do
    group(items, [[]])
  end
  def group([head | tail], [[head | _] = acc_head | acc_tail]) do
    group(tail, [[head | acc_head] | acc_tail])
  end
  def group([head | tail], [[]]) do
    group(tail, [[head]])
  end
  def group([head | tail], acc) do
    group(tail, [[head] | acc])
  end
  def group([], acc) do
    Enum.reverse(acc)
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
