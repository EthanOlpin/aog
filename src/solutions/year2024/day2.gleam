import gleam/io
import gleam/list
import input
import parse

fn safe_pair(a, b) {
  a < b && b - a <= 3
}

fn safe_triple(a, b, c) {
  safe_pair(a, b) && safe_pair(b, c)
}

fn all_safe(xs: List(Int)) -> Bool {
  case xs {
    [] | [_] -> True
    [a, b, ..rest] -> safe_pair(a, b) && all_safe([b, ..rest])
  }
}

fn all_safe_tolerant(xs: List(Int)) -> Bool {
  case xs {
    [] | [_] -> True
    [a, b, ..rest] ->
      { !safe_pair(a, b) && all_safe([b, ..rest]) } || do_all_safe_tolerant(xs)
  }
}

fn do_all_safe_tolerant(xs: List(Int)) -> Bool {
  case xs {
    [] | [_] | [_, _] -> True
    [a, b, c, ..rest] ->
      { !safe_triple(a, b, c) && all_safe([a, c, ..rest]) }
      || { safe_pair(a, b) && do_all_safe_tolerant([b, c, ..rest]) }
  }
}

pub fn main() {
  let reports = input.get() |> parse.lines |> list.map(parse.ints)
  list.count(reports, fn(report) {
    all_safe(report) || all_safe(list.reverse(report))
  })
  |> io.debug

  list.count(reports, fn(report) {
    all_safe_tolerant(report) || all_safe_tolerant(list.reverse(report))
  })
  |> io.debug
}
