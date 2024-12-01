import gleam/int
import gleam/list
import gleam/regexp
import gleam/string

pub fn ints(s: String) -> List(Int) {
  let assert Ok(re) = regexp.from_string("\\d+")
  regexp.scan(re, s) |> list.filter_map(fn(match) { int.parse(match.content) })
}

pub fn digits(s: String) -> List(Int) {
  let assert Ok(re) = regexp.from_string("\\d")
  regexp.scan(re, s) |> list.filter_map(fn(match) { int.parse(match.content) })
}

pub fn lines(s: String) -> List(String) {
  string.split(s, "\n")
}
