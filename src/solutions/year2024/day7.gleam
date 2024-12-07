import gleam/int
import gleam/io
import gleam/list
import input
import num
import parse

type Operator {
  Add
  Mul
  Concat
}

fn apply_operator(op, a, b) {
  case op {
    Add -> a + b
    Mul -> a * b
    Concat -> num.concat(a, b)
  }
}

type Equation {
  Equation(target: Int, operands: List(Int))
}

fn try_solve(equation, ops) {
  case equation {
    Equation(target, [final]) if final == target -> Ok(target)
    Equation(_, [a, b, ..rest]) -> {
      use op <- list.find_map(ops)
      let operands = [apply_operator(op, a, b), ..rest]
      try_solve(Equation(..equation, operands:), ops)
    }
    _ -> Error(Nil)
  }
}

fn parse_equation(line) {
  let line = line |> parse.ints
  let assert [target, ..operands] = line
  Equation(target: target, operands:)
}

pub fn main() {
  let input = input.get() |> parse.lines |> list.map(parse_equation)
  list.filter_map(input, try_solve(_, [Add, Mul]))
  |> int.sum
  |> io.debug

  list.filter_map(input, try_solve(_, [Add, Mul, Concat]))
  |> int.sum
  |> io.debug
}
