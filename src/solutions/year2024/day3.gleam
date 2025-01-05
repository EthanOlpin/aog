import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/regexp
import gleam/string
import input
import parse

pub fn main() {
  let assert Ok(instruction_pattern) =
    regexp.from_string("do\\(\\)|mul\\(\\d+,\\d+\\)|don't\\(\\)")
  let instructions =
    input.get()
    |> regexp.scan(instruction_pattern, _)
    |> list.map(fn(result) { result.content })

  instructions
  |> list.filter(string.starts_with(_, "mul"))
  |> list.map(parse.ints)
  |> list.map(int.product)
  |> int.sum
  |> io.debug

  instructions
  |> list.map_fold(True, fn(enabled, instruction) {
    case instruction {
      "do()" -> #(True, 0)
      "don't()" -> #(False, 0)
      "mul" <> args ->
        case enabled {
          True -> #(True, parse.ints(args) |> int.product)
          False -> #(False, 0)
        }
      _ -> panic as "unreachable"
    }
  })
  |> pair.second
  |> int.sum
  |> io.debug
}
