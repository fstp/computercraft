defmodule Gen do
  def main do
    layers = File.read!("blueprint.txt")
    |> String.split("\n", trim: true)
    |> create_layers(%{layers: []}, 1)
    
    IO.puts lua_functions
    IO.puts layers.layers
  end

  def create_layers([head | tail], state, depth) do
    {_x, length} = parse_dimensions(head)
    {rows, tail} = Enum.split(tail, length)
    create_layers(
      tail,
      %{state | layers: [parse_layer(rows, length, depth) | state.layers]},
      depth+1)
  end
  def create_layers([], state, _depth) do
    %{state | layers: Enum.reverse(state.layers)}
  end

  def parse_layer(rows, length, depth) do
    rows
    |> align_rows(depth)
    |> Enum.zip(1..100000) # TODO(john) hackish, could be solved in a nicer way
    |> Enum.map(fn row -> parse_row(row, length, depth) end)
  end

  def align_rows(rows, depth) do
    case rem(depth, 2) == 0 do
      true -> rows
      false -> Enum.reverse(rows)
    end
  end

  def parse_row({data, idx}, length, depth) do
    data
    |> String.split("", trim: true)
    |> align_slots(idx)
    |> add_turn(idx, length, depth)
    |> group
    |> Enum.map(fn group -> to_lua(group, length(group)) end)
    # |> trace
  end

  def align_slots(data, idx) do
    case rem(idx, 2) == 0 do
      true ->
        Enum.reverse(data)
      false ->
        data
    end
  end

  def add_turn(data, length, length, _depth) do
    List.update_at(data, -1, fn slot -> [slot, "H"] end)
  end
  def add_turn(data, idx, _length, depth) do
    # TODO(john) refactor into a function, describe better why
    case rem(idx, 2) != rem(depth, 2) do
      true ->
        List.update_at(data, -1, fn slot -> [slot, "R"] end)
      false ->
        List.update_at(data, -1, fn slot -> [slot, "L"] end)
    end
  end

  def to_lua(["0"], 1) do
    ["dig()\n"]
  end
  def to_lua([slot], 1) when is_binary(slot) do
    ["fill(", slot, ")\n"]
  end
  def to_lua([[slot, "R"]], 1) do
    ["digRight(", slot, ")\n"]
  end
  def to_lua([[slot, "L"]], 1) do
    ["digLeft(", slot, ")\n"]
  end
  def to_lua([[slot, "H"]], 1) do
    ["down(", slot, ")\n"]
  end
  def to_lua([head | _tail], length) do
    ["for i=1,", Integer.to_string(length), " do\n",
     to_lua([head], 1),
     "end\n"]
  end

  def lua_functions() do
    [lua_fun_dig(),
     lua_fun_turn_around(),
     lua_fun_refill(),
     lua_fun_refill_place(),
     lua_fun_refill_placeUp(),
     lua_fun_down(),
     lua_fun_dig_right(),
     lua_fun_dig_left(),
     lua_fun_fill()]
  end

  def lua_fun_dig() do
    ["function dig()\n",
     "turtle.dig()\n",
     "turtle.forward()\n",
     "end\n"]
  end
  def lua_fun_turn_around() do
    ["function turnAround()\n",
     "turtle.turnLeft()\n",
     "turtle.turnLeft()\n",
     "end\n"]
  end
  def lua_fun_refill() do
    ["function refill(slot)\n",
     "if turtle.getItemCount(slot) == 1 then\n",
     "local to = turtle.getItemDetail(slot)\n",
     "for i=1,16 do\n",
     "if i ~= slot then\n",
     "local from = turtle.getItemDetail(i)\n",
     "if from and from.name == to.name then\n",
     "turtle.select(i)\n",
     "turtle.transferTo(slot)\n",
     "end\n",
     "end\n",
     "end\n",
     "end\n",
     "end\n"]
  end
  def lua_fun_refill_place() do
    ["function place(slot)\n",
     "refill(slot)\n",
     "turtle.select(slot)\n",
     "turtle.place()\n",
     "end\n"]
  end
  def lua_fun_refill_placeUp() do
    ["function placeUp(slot)\n",
     "refill(slot)\n",
     "turtle.select(slot)\n",
     "turtle.placeUp()\n",
     "end\n"]
  end
  def lua_fun_down() do
    ["function down(slot)\n",
     "turtle.digDown()\n",
     "turtle.down()\n",
     "turnAround()\n",
     "if slot ~= 0 then\n",
     "placeUp(slot)\n",
     "end\n",
     "end\n"]
  end
  def lua_fun_dig_right() do
    ["function digRight(slot)\n",
     "turtle.turnRight()\n",
     "dig()\n",
     "turtle.turnRight()\n",
     "if slot ~= 0 then\n",
     "turtle.turnRight()\n",
     "place(slot)\n",
     "turtle.turnLeft()\n",
     "end\n",
     "end\n"]
  end
  def lua_fun_dig_left() do
    ["function digLeft(slot)\n",
     "turtle.turnLeft()\n",
     "dig()\n",
     "turtle.turnLeft()\n",
     "if slot ~= 0 then\n",
     "turtle.turnLeft()\n",
     "place(slot)\n",
     "turtle.turnRight()\n",
     "end\n",
     "end\n"]
  end
  def lua_fun_fill() do
    ["function fill(slot)\n",
     "dig()\n",
     "turnAround()\n",
     "place(slot)\n",
     "turnAround()\n",
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

  def trace(args, opts \\ :none)
  def trace(args, opts) when is_binary(args) do
    case opts do
      :none ->
        IO.puts args
      :newline ->
        IO.puts args <> "\n"
    end
    args
  end
  def trace(args, opts) do
    case opts do
      :none ->
        IO.inspect args
      :newline ->
        IO.puts "#{inspect args}\n"
    end
  end
end
