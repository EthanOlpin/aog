import gleam/io
import gleam/list
import gleam/string
import input
import parse

fn bar_height(bar: List(String), char) -> Int {
  do_bar_height(bar, char, 0)
}

fn do_bar_height(bar, char, acc) {
  case bar {
    [c, ..rest] if c == char -> do_bar_height(rest, char, acc + 1)
    [] | [_, ..] -> acc
  }
}

fn key_pin_heights(columns) {
  list.map(columns, bar_height(_, ".")) |> list.map(fn(h) { 7 - h })
}

fn lock_pin_heights(columns) {
  list.map(columns, bar_height(_, "#"))
}

fn fit(key_pin_heights, lock_pin_heights) {
  let pairs = list.zip(key_pin_heights, lock_pin_heights)
  use #(key_pin_height, lock_pin_height) <- list.all(pairs)
  key_pin_height + lock_pin_height <= 7
}

fn count_pairs_that_fit(keys, locks) {
  let keys = list.map(keys, key_pin_heights)
  let locks = list.map(locks, lock_pin_heights)
  use count, key_heights <- list.fold(keys, 0)
  use count, lock_heights <- list.fold(locks, count)
  case fit(key_heights, lock_heights) {
    True -> count + 1
    False -> count
  }
}

pub fn main() {
  let rows =
    input.get()
    |> parse.split("\n\n")
    |> list.map(parse.lines)
    |> list.map(list.map(_, string.split(_, "")))

  let #(locks, keys) =
    list.partition(rows, fn(chunk) {
      let assert [first_row, ..] = chunk
      list.all(first_row, fn(cell) { cell == "#" })
    })

  let keys = list.map(keys, list.transpose)
  let locks = list.map(locks, list.transpose)

  count_pairs_that_fit(keys, locks) |> io.debug
}
