import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import input
import parse

type State {
  State(
    pointer: Int,
    register_a: Int,
    register_b: Int,
    register_c: Int,
    output: List(Int),
  )
}

fn execute(program: List(Int), register_a: Int) {
  let start = State(0, register_a, 0, 0, [])
  let instruction_lookup =
    program
    |> list.window_by_2
    |> list.index_map(fn(ab, i) { #(i, ab) })
    |> dict.from_list
  let get_instruction = dict.get(instruction_lookup, _)
  let final_state = do_execute(start, get_instruction)
  final_state.output |> list.reverse
}

fn do_execute(
  state: State,
  get_instruction: fn(Int) -> Result(#(Int, Int), Nil),
) {
  case get_instruction(state.pointer) {
    Ok(#(opcode, operand)) ->
      execute_instruction(opcode, operand, state) |> do_execute(get_instruction)
    Error(Nil) -> state
  }
}

fn execute_instruction(opcode: Int, operand: Int, state: State) {
  let combo = fn(operand) {
    case operand {
      0 | 1 | 2 | 3 -> operand
      4 -> state.register_a
      5 -> state.register_b
      6 -> state.register_c
      _ -> 2
    }
  }

  case opcode {
    0 -> {
      let register_a = int.bitwise_shift_right(state.register_a, combo(operand))
      let pointer = state.pointer + 2
      State(..state, pointer:, register_a:)
    }
    1 -> {
      let register_b = int.bitwise_exclusive_or(state.register_b, operand)
      let pointer = state.pointer + 2
      State(..state, pointer:, register_b:)
    }
    2 -> {
      let register_b = combo(operand) % 8
      let pointer = state.pointer + 2
      State(..state, pointer:, register_b:)
    }
    3 -> {
      case state.register_a == 0 {
        True -> State(..state, pointer: state.pointer + 2)
        False -> State(..state, pointer: operand)
      }
    }
    4 -> {
      let register_b =
        int.bitwise_exclusive_or(state.register_b, state.register_c)
      let pointer = state.pointer + 2
      State(..state, pointer:, register_b:)
    }
    5 -> {
      let output = [combo(operand) % 8, ..state.output]
      let pointer = state.pointer + 2
      State(..state, pointer:, output:)
    }
    6 -> {
      let register_b = int.bitwise_shift_right(state.register_a, combo(operand))
      let pointer = state.pointer + 2
      State(..state, pointer:, register_b:)
    }
    7 -> {
      let register_c = int.bitwise_shift_right(state.register_a, combo(operand))
      let pointer = state.pointer + 2
      State(..state, pointer:, register_c:)
    }
    _ -> panic as "unexpected op code"
  }
}

fn find_inputs_that_produce(output, execute) {
  case output {
    [_, ..suffix] ->
      find_inputs_that_produce(suffix, execute)
      |> list.flat_map(fn(suffix_input) {
        list.range(suffix_input * 8, suffix_input * 8 + 7)
      })
      |> list.filter(fn(input) { execute(input) == output })
    [] -> [0]
  }
}

pub fn main() {
  let assert [registers, program] = input.get() |> parse.split("\n\n")
  let assert [register_a, ..] = registers |> parse.ints
  let program = program |> parse.ints

  execute(program, register_a)
  |> list.map(int.to_string)
  |> string.join(",")
  |> io.println

  let assert [program, ..] =
    find_inputs_that_produce(
      [2, 4, 1, 5, 7, 5, 1, 6, 0, 3, 4, 3, 5, 5, 3, 0],
      execute(program, _),
    )

  io.debug(program)
}
