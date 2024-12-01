import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import input
import misc.{idc}
import parse

pub fn solve() {
  let #(left, right) =
    parse.lines(input.get())
    |> list.map(parse.ints)
    |> list.fold(#([], []), fn(acc, xs) {
      let assert [a, b] = xs
      let #(left, right) = acc
      #([a, ..left], [b, ..right])
    })

  list.sort(left, int.compare)
  |> list.zip(list.sort(right, int.compare))
  |> list.fold(0, fn(sum, pair) { sum + int.absolute_value(pair.0 - pair.1) })
  |> io.debug

  let right_counts =
    list.fold(right, dict.new(), fn(counts, x) {
      dict.upsert(counts, x, fn(c) { option.unwrap(c, 0) + 1 })
    })

  list.fold(left, 0, fn(sum, a) {
    sum + a * result.unwrap(dict.get(right_counts, a), 0)
  })
  |> io.debug
}

pub fn main() {
  solve()
}
