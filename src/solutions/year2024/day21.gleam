import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/string
import input
import parse
import position.{type Direction, type Position, Down, Left, Position, Right, Up}

const num_pad_activate = Position(3, 2)

const num_pad_gap = Position(3, 0)

const arrow_key_activate = Position(0, 2)

const arrow_keys_gap = Position(0, 0)

fn num_pad_pos(digit: String) {
  case digit {
    "0" -> Position(3, 1)
    "1" -> Position(2, 0)
    "2" -> Position(2, 1)
    "3" -> Position(2, 2)
    "4" -> Position(1, 0)
    "5" -> Position(1, 1)
    "6" -> Position(1, 2)
    "7" -> Position(0, 0)
    "8" -> Position(0, 1)
    "9" -> Position(0, 2)
    "A" -> num_pad_activate
    _ -> panic as "unknown num key"
  }
}

fn arrow_key_pos(direction: Direction) {
  case direction {
    Up -> Position(0, 1)
    Left -> Position(1, 0)
    Down -> Position(1, 1)
    Right -> Position(1, 2)
    _ -> panic as "unknown arrow key"
  }
}

fn directions_between(a: Position, b: Position, gap: Position) {
  let Position(drow, dcol) = position.sub(b, a)

  let row_dirs = case int.compare(drow, 0) {
    order.Lt -> list.repeat(Up, -drow)
    order.Eq -> []
    order.Gt -> list.repeat(Down, drow)
  }

  let col_dirs = case int.compare(dcol, 0) {
    order.Lt -> list.repeat(Left, -dcol)
    order.Eq -> []
    order.Gt -> list.repeat(Right, dcol)
  }

  list.append(row_dirs, col_dirs)
  |> list.permutations
  |> list.unique
  |> list.filter(fn(directions) {
    let has_gap =
      list.scan(directions, a, position.shift)
      |> list.contains(gap)
    !has_gap
  })
}

type Memo =
  Dict(#(Position, Position, Int), Int)

fn memoized(memo: Dict(k, v), key: k, f: fn() -> #(Dict(k, v), v)) {
  case dict.get(memo, key) {
    Ok(res) -> #(memo, res)
    Error(Nil) -> {
      let #(memo, res) = f()
      #(dict.insert(memo, key, res), res)
    }
  }
}

fn min_movement_command_count(
  memo: Memo,
  origin: Position,
  dest: Position,
  gap: Position,
  chain_length: Int,
) -> #(Memo, Int) {
  use <- memoized(memo, #(origin, dest, chain_length))
  let directions_seqs = directions_between(origin, dest, gap)
  let #(memo, minimum_opt) =
    find_min_movement_command_count(memo, directions_seqs, chain_length, None)
  let minimum = minimum_opt |> option.unwrap(0)
  let memo = dict.insert(memo, #(origin, dest, chain_length), minimum)
  #(memo, minimum)
}

fn find_min_movement_command_count(
  memo: Memo,
  directions_seqs: List(List(Direction)),
  chain_length: Int,
  min: Option(Int),
) {
  case directions_seqs {
    [directions, ..rest] -> {
      let #(memo, length) =
        movement_command_count(memo, directions, chain_length)
      let min = option.map(min, int.min(_, length)) |> option.unwrap(length)
      find_min_movement_command_count(memo, rest, chain_length, Some(min))
    }
    [] -> #(memo, min)
  }
}

fn movement_command_count(
  memo: Memo,
  directions: List(Direction),
  chain_length: Int,
) -> #(Memo, Int) {
  use <- bool.guard(chain_length == 0, #(memo, list.length(directions) + 1))
  let arrow_keys = make_arrow_key_sequence(directions)
  sequence_command_count(memo, arrow_keys, arrow_keys_gap, chain_length - 1, 0)
}

fn make_arrow_key_sequence(directions: List(Direction)) {
  let arrow_keys = list.map(directions, arrow_key_pos)
  list.flatten([[arrow_key_activate], arrow_keys, [arrow_key_activate]])
}

fn sequence_command_count(
  memo: Memo,
  positions: List(Position),
  gap: Position,
  chain_length: Int,
  total: Int,
) -> #(Memo, Int) {
  case positions {
    [_] -> #(memo, total)
    [origin, dest, ..rest] -> {
      let #(memo, movement_commands) =
        min_movement_command_count(memo, origin, dest, gap, chain_length)
      let total = total + movement_commands
      sequence_command_count(memo, [dest, ..rest], gap, chain_length, total)
    }
    [] -> panic as "cannot find length of empty sequence"
  }
}

fn code_complexity(code: String, robot_count: Int) {
  let positions =
    string.to_graphemes(code)
    |> list.map(num_pad_pos)
    |> list.prepend(num_pad_activate)

  let #(_, length) =
    sequence_command_count(dict.new(), positions, num_pad_gap, robot_count, 0)

  parse.int(code) * length
}

pub fn main() {
  let sequences =
    input.get()
    |> parse.lines

  list.map(sequences, code_complexity(_, 2))
  |> int.sum
  |> io.debug

  list.map(sequences, code_complexity(_, 25))
  |> int.sum
  |> io.debug
}
