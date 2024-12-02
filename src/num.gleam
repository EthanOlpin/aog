import gleam/int

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
