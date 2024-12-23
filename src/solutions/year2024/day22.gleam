import defaultdict
import gleam/int
import gleam/io
import gleam/list
import input
import num
import parse

const xor = int.bitwise_exclusive_or

const and = int.bitwise_and

const bsl = int.bitwise_shift_left

const bsr = int.bitwise_shift_right

fn prune(num: Int) {
  num |> and(16_777_215)
}

fn mix(num: Int, pow2: Int) {
  case pow2 < 0 {
    True -> num |> bsr(-pow2) |> xor(num)
    False -> num |> bsl(pow2) |> xor(num)
  }
}

fn evolve(num: Int) {
  num
  |> mix(6)
  |> prune
  |> mix(-5)
  |> prune
  |> mix(11)
  |> prune
}

fn nth(num: Int, n: Int) {
  case n == 0 {
    True -> num
    False -> evolve(num) |> nth(n - 1)
  }
}

fn sequence(num: Int, length: Int) {
  [num, ..list.scan(list.range(1, length), num, fn(n, _) { evolve(n) })]
}

fn ones(num: Int) {
  num.unsafe_mod(num, 10)
}

fn price_after_sequence(start: Int, sequence_length: Int) {
  sequence(start, sequence_length)
  |> list.reverse
  |> list.map(ones)
  |> list.window(5)
  |> list.map(fn(prices) {
    let assert [last, ..] = prices
    let assert [d, c, b, a] =
      list.map(prices, ones)
      |> list.window_by_2
      |> list.map(fn(pair) { pair.0 - pair.1 })
    #(#(a, b, c, d), last)
  })
  |> defaultdict.from_list(0)
}

pub fn main() {
  let numbers = input.get() |> parse.ints()
  numbers |> list.map(nth(_, 2000)) |> int.sum |> io.debug

  let assert Ok(max_price) =
    list.fold(numbers, defaultdict.new(0), fn(all, start) {
      let sequences_prices = price_after_sequence(start, 2000)
      defaultdict.combine(all, sequences_prices, int.add)
    })
    |> defaultdict.values
    |> list.reduce(int.max)

  io.debug(max_price)
}
