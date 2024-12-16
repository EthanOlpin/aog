import gleam/int
import gleam/list
import gleam/regexp
import gleam/string
import grid.{type Grid}

pub fn ints(s: String) -> List(Int) {
  let assert Ok(re) = regexp.from_string("-?\\d+")
  regexp.scan(re, s) |> list.filter_map(fn(match) { int.parse(match.content) })
}

pub fn digits(s: String) -> List(Int) {
  let assert Ok(re) = regexp.from_string("\\d")
  regexp.scan(re, s) |> list.filter_map(fn(match) { int.parse(match.content) })
}

pub fn lines(s: String) -> List(String) {
  split(s, "\n")
}

pub fn split(s: String, pattern: String) -> List(String) {
  let assert Ok(re) = regexp.from_string(pattern)
  regexp.split(re, s) |> list.filter(fn(s) { s != "" })
}

pub fn grid(
  input: String,
  row_sep_pattern: String,
  col_sep_pattern: String,
) -> Grid(String) {
  input
  |> string.trim
  |> split(row_sep_pattern)
  |> list.map(split(_, col_sep_pattern))
  |> grid.from_list
}
