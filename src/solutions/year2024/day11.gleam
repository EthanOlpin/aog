import defaultdict
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import input
import num
import parse

fn expand(n: Int) -> List(Int) {
  let len = num.len(n)
  case n {
    0 -> [1]
    _ if len % 2 == 0 -> num.split(n, len / 2)
    _ -> [n * 2024]
  }
}

fn repeatedly_expand(counts, i) {
  case i == 0 {
    True -> counts
    False -> {
      let counter = defaultdict.new_counter()
      defaultdict.to_dict(counts)
      |> dict.fold(counter, fn(counter, key, count) {
        expand(key)
        |> list.fold(counter, fn(counter, key) {
          defaultdict.counter_add(counter, key, count)
        })
      })
      |> repeatedly_expand(i - 1)
    }
  }
}

pub fn main() {
  let counts =
    input.get()
    |> parse.ints()
    |> defaultdict.counter_from_list

  repeatedly_expand(counts, 25) |> defaultdict.values |> int.sum |> io.debug

  repeatedly_expand(counts, 75) |> defaultdict.values |> int.sum |> io.debug
}
