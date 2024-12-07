import gleam/float
import gleam/int
import gleam_community/maths/elementary

pub fn diff(a: Int, b: Int) -> Int {
  int.absolute_value(a - b)
}

pub fn wrap(x: Int, min: Int, max: Int) -> Int {
  unsafe_mod(x - min, max - min) + min
}

pub fn wrap_index(index: Int, length: Int) -> Int {
  wrap(index, 0, length)
}

pub fn unsafe_mod(x: Int, y: Int) -> Int {
  // https://en.wikipedia.org/wiki/Modulo#Variants_of_the_definition
  let assert Ok(r) = int.modulo(x, y)
  r
}

pub fn len(a: Int) -> Int {
  let assert Ok(log10) = int.to_float(a) |> elementary.logarithm_10
  log10 |> float.truncate |> int.add(1)
}

pub fn concat(a: Int, b: Int) -> Int {
  let b_len = len(b)
  let assert Ok(multiplier) = int.power(10, b_len |> int.to_float)
  let multiplier = multiplier |> float.truncate
  a * multiplier + b
}
