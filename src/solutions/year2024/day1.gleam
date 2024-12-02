import defaultdict
import gleam/int
import gleam/io
import gleam/list
import input
import num
import parse

pub fn main() {
  let assert [left, right] =
    input.get()
    |> parse.lines
    |> list.map(parse.ints)
    |> list.transpose

  list.sort(left, int.compare)
  |> list.map2(right, num.diff)
  |> int.sum
  |> io.debug

  let right_counts = defaultdict.counter_from_list(right)

  list.map(left, defaultdict.get(right_counts, _))
  |> list.map2(left, int.multiply)
  |> int.sum
  |> io.debug
}
