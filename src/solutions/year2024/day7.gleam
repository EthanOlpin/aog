import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import input
import num
import parse

type Operator {
  Add
  Multiply
  Concat
}

fn unapply_operator(op, a, b) {
  case op {
    Add if a >= b -> Ok(a - b)
    Multiply if b != 0 && a % b == 0 -> Ok(a / b)
    Concat -> {
      use <- bool.guard(!num.has_suffix(a, b), Error(Nil))
      Ok(num.strip_suffix(a, b))
    }
    _ -> Error(Nil)
  }
}

type Equation {
  Equation(aggregate: Int, operands: List(Int))
}

fn try_solve(equation, ops) {
  case equation {
    Equation(aggregate, []) if aggregate == 0 -> Ok(aggregate)
    Equation(aggregate, [a, ..operands]) -> {
      use op <- list.find_map(ops)
      use unapplied <- result.try(unapply_operator(op, aggregate, a))
      try_solve(Equation(aggregate: unapplied, operands:), ops)
      |> result.replace(aggregate)
    }
    _ -> Error(Nil)
  }
}

fn parse_equation(line) {
  let line = line |> parse.ints
  let assert [aggregate, ..operands] = line
  Equation(aggregate:, operands: list.reverse(operands))
}

pub fn main() {
  let input = input.get() |> parse.lines |> list.map(parse_equation)
  list.filter_map(input, try_solve(_, [Add, Multiply]))
  |> int.sum
  |> io.debug

  list.filter_map(input, try_solve(_, [Add, Multiply, Concat]))
  |> int.sum
  |> io.debug
}
