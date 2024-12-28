import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/string
import input
import num
import parse

type Operation {
  And
  Xor
  Or
}

type Gate {
  Gate(String, Operation, String)
}

type Wire {
  Input(id: String)
  Interior(id: String, Gate)
}

type Circuit {
  Circuit(wires: Dict(String, Wire), input_values: Dict(String, Bool))
}

fn new_circuit() {
  Circuit(wires: dict.new(), input_values: dict.new())
}

fn insert_input(circuit: Circuit, id, value) {
  let wires = dict.insert(circuit.wires, id, Input(id))
  let input_values = dict.insert(circuit.input_values, id, value)
  Circuit(input_values:, wires:)
}

fn insert_gate(circuit: Circuit, id, gate) {
  let wires = dict.insert(circuit.wires, id, Interior(id, gate))
  Circuit(..circuit, wires:)
}

fn get_wire(circuit: Circuit, id) {
  let assert Ok(wire) = dict.get(circuit.wires, id)
  wire
}

fn get_value(circuit: Circuit, id) {
  let assert Ok(val) = dict.get(circuit.input_values, id)
  val
}

fn size(circuit: Circuit) {
  dict.size(circuit.input_values) / 2
}

type AdderComponent {
  Sum(bit: Int)
  Carry(bit: Int)
  RepeatCarry(bit: Int)
  DirectCarry(bit: Int)
  Output(bit: Int)
  InputIndex
}

fn find_adder_component(circuit: Circuit, component) {
  dict.values(circuit.wires)
  |> list.find_map(fn(wire) {
    case component {
      Sum(bit) -> is_sum(circuit, bit, wire.id)
      Carry(bit) -> is_carry(circuit, bit, wire.id)
      DirectCarry(bit) -> is_direct_carry(circuit, bit, wire.id)
      RepeatCarry(bit) -> is_repeat_carry(circuit, bit, wire.id)
      Output(bit) -> is_output(circuit, bit, wire.id)
      InputIndex -> panic as "inputs shouldn't be swapped"
    }
  })
}

fn commutative_check(l, r, validate1, validate2, both_ok, both_invalid) {
  case validate1(l), validate2(r) {
    Ok(_), Ok(_) -> Ok(both_ok)
    Ok(_), err | err, Ok(_) -> err
    _, _ ->
      case validate1(r), validate2(l) {
        Ok(_), Ok(_) -> Ok(both_ok)
        Ok(_), err | err, Ok(_) -> err
        _, _ -> Error(both_invalid)
      }
  }
}

fn is_output(circuit, bit, id) {
  let expected = Output(bit)
  let size = size(circuit)
  case get_wire(circuit, id) {
    _ if bit == 0 -> is_sum(circuit, bit, id)
    _ if bit == size -> is_carry(circuit, bit - 1, id)
    Interior(id, Gate(l, Xor, r)) -> {
      let is_carry = is_carry(circuit, bit - 1, _)
      let is_sum = is_sum(circuit, bit, _)
      commutative_check(l, r, is_sum, is_carry, id, #(id, expected))
    }
    _ -> Error(#(id, expected))
  }
}

fn is_sum(circuit, bit, id) {
  let expected = Sum(bit)
  case get_wire(circuit, id) {
    Interior(_, Gate(l, Xor, r)) -> {
      let is_input = is_input(circuit, bit, _)
      commutative_check(l, r, is_input, is_input, id, #(id, expected))
    }
    _ -> Error(#(id, expected))
  }
}

fn is_carry(circuit, bit, id) {
  let expected = Carry(bit)
  case get_wire(circuit, id) {
    _ if bit == 0 -> is_direct_carry(circuit, bit, id)
    Interior(id, Gate(l, Or, r)) -> {
      let is_direct_carry = is_direct_carry(circuit, bit, _)
      let is_repeat_carry = is_repeat_carry(circuit, bit, _)
      commutative_check(l, r, is_direct_carry, is_repeat_carry, id, #(
        id,
        expected,
      ))
    }
    _ -> Error(#(id, expected))
  }
}

fn is_direct_carry(circuit, bit, id) {
  let expected = DirectCarry(bit)
  case get_wire(circuit, id) {
    Interior(id, Gate(l, And, r)) -> {
      let is_input = is_input(circuit, bit, _)
      commutative_check(l, r, is_input, is_input, id, #(id, expected))
    }
    _ -> Error(#(id, expected))
  }
}

fn is_repeat_carry(circuit, bit, id) {
  let expected = RepeatCarry(bit)
  case get_wire(circuit, id) {
    Interior(id, Gate(l, And, r)) -> {
      let is_sum = is_sum(circuit, bit, _)
      let is_direct_carry = is_carry(circuit, bit - 1, _)
      commutative_check(l, r, is_sum, is_direct_carry, id, #(id, expected))
    }
    _ -> Error(#(id, expected))
  }
}

fn is_input(circuit, bit, id) {
  let expected = InputIndex
  case get_wire(circuit, id) {
    Input(id) ->
      case string.contains(id, int.to_string(bit)) {
        True -> Ok(id)
        False -> Error(#(id, expected))
      }
    Interior(_, _) -> Error(#(id, expected))
  }
}

fn swap(circuit: Circuit, a_id, b_id) {
  let a = get_wire(circuit, a_id)
  let b = get_wire(circuit, b_id)
  let wires =
    dict.insert(circuit.wires, a_id, b)
    |> dict.insert(b_id, a)
  Circuit(..circuit, wires:)
}

fn swap_gates_until_adder(circuit: Circuit, outputs) {
  do_swap_gates_until_adder(circuit, 0, outputs, [])
}

fn do_swap_gates_until_adder(circuit: Circuit, bit, outputs, swaps) {
  case outputs {
    [out, ..rest] ->
      case is_output(circuit, bit, out) {
        Ok(_) -> do_swap_gates_until_adder(circuit, bit + 1, rest, swaps)
        Error(#(bad_gate_id, expected)) -> {
          let assert Ok(valid_gate_id) = find_adder_component(circuit, expected)
          let new_circuit = swap(circuit, bad_gate_id, valid_gate_id)
          let swaps = [bad_gate_id, valid_gate_id, ..swaps]
          do_swap_gates_until_adder(new_circuit, bit, outputs, swaps)
        }
      }
    [] -> swaps
  }
}

fn evaluate(circuit: Circuit, outputs) {
  outputs
  |> list.map(evaluate_wire(circuit, _))
  |> num.from_binary
}

fn evaluate_wire(circuit: Circuit, wire_id) {
  let wire = get_wire(circuit, wire_id)
  case wire {
    Input(id) -> get_value(circuit, id)
    Interior(_, Gate(a, op, b)) -> {
      let a = evaluate_wire(circuit, a)
      let b = evaluate_wire(circuit, b)
      case op {
        And -> a && b
        Or -> a || b
        Xor -> a != b
      }
    }
  }
}

fn parse_circuit(raw) {
  parse.split(raw, "\n+")
  |> list.fold(new_circuit(), fn(circuit, line) {
    case parse.split(line, "\\s|:") {
      [id, value] -> insert_input(circuit, id, value == "1")
      [l, "AND", r, "->", id] -> insert_gate(circuit, id, Gate(l, And, r))
      [l, "OR", r, "->", id] -> insert_gate(circuit, id, Gate(l, Or, r))
      [l, "XOR", r, "->", id] -> insert_gate(circuit, id, Gate(l, Xor, r))
      _ -> panic as "invalid input"
    }
  })
}

pub fn main() {
  let circuit = parse_circuit(input.get())
  let outputs =
    circuit.wires
    |> dict.keys
    |> list.filter(string.starts_with(_, "z"))
    |> list.sort(string.compare)

  evaluate(circuit, outputs) |> io.debug

  swap_gates_until_adder(circuit, outputs)
  |> list.sort(string.compare)
  |> string.join(",")
  |> io.println
}
