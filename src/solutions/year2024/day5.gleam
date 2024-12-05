import defaultdict
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/set
import input
import parse

fn is_correct(rules, update) {
  case update {
    [] | [_] -> True
    [a, ..rest] -> {
      let rest_set = set.from_list(rest)
      let successor_set = defaultdict.get(rules, a)
      set.is_subset(rest_set, successor_set) && is_correct(rules, rest)
    }
  }
}

fn middle(xs) {
  do_middle(xs, xs)
}

fn do_middle(slow, fast) {
  case slow, fast {
    [x, ..], [] | [x, ..], [_] -> x
    [_, ..xs], [_, _, ..ys] -> do_middle(xs, ys)
    [], _ -> panic as "unreachable"
  }
}

fn compare(a: Int, b: Int, rules: defaultdict.DefaultDict(Int, set.Set(Int))) {
  case defaultdict.get(rules, a) |> set.contains(b) {
    True -> order.Lt
    False -> order.Gt
  }
}

pub fn main() {
  let assert [rules, updates] = input.get() |> parse.split("\n\n")
  let rules =
    rules
    |> parse.split("\n")
    |> list.map(parse.ints)
    |> list.fold(defaultdict.new(set.new()), fn(rules, ab) {
      let assert [a, b] = ab
      defaultdict.upsert(rules, a, set.insert(_, b))
    })

  let updates =
    updates
    |> parse.split("\n")
    |> list.map(parse.ints)

  let #(correct, incorrect) =
    updates
    |> list.partition(is_correct(rules, _))

  list.map(correct, middle) |> int.sum |> io.debug

  incorrect
  |> list.map(list.sort(_, fn(a, b) { compare(a, b, rules) }))
  |> list.map(middle)
  |> int.sum
  |> io.debug
}
