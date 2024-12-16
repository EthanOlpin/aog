import gleam/int
import gleam/io
import gleam/list
import gleam/result
import input
import num
import parse

type Machine {
  Machine(adx: Float, ady: Float, bdx: Float, bdy: Float, px: Float, py: Float)
}

fn parse_machine(chunk: String) {
  let assert [adx, ady, bdx, bdy, px, py] =
    chunk |> parse.ints |> list.map(int.to_float)
  Machine(adx, ady, bdx, bdy, px, py)
}

fn solve_for_tokens(machine: Machine) -> Result(Int, Nil) {
  let Machine(adx, ady, bdx, bdy, px, py) = machine
  let denom = adx *. bdy -. ady *. bdx
  let a_presses = { px *. bdy -. py *. bdx } /. denom
  let b_presses = { py *. adx -. px *. ady } /. denom
  use a_presses <- result.try(num.as_int(a_presses))
  use b_presses <- result.try(num.as_int(b_presses))
  Ok(a_presses * 3 + b_presses)
}

pub fn main() {
  let machines =
    input.get()
    |> parse.split("\n\n")
    |> list.map(parse_machine)

  machines |> list.filter_map(solve_for_tokens) |> int.sum |> io.debug

  let prize_delta = 10_000_000_000_000.0

  machines
  |> list.map(fn(machine) {
    Machine(
      ..machine,
      px: machine.px +. prize_delta,
      py: machine.py +. prize_delta,
    )
  })
  |> list.filter_map(solve_for_tokens)
  |> int.sum
  |> io.debug
}
