import gleam/bool
import gleam/float
import gleam/int
import gleam/list
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

pub fn is_int(a: Float) -> Bool {
  float.floor(a) == a
}

pub fn as_int(a: Float) -> Result(Int, Nil) {
  case is_int(a) {
    True -> Ok(float.truncate(a))
    False -> Error(Nil)
  }
}

pub fn assert_int(a: Float) -> Int {
  let assert Ok(result) = as_int(a)
  result
}

pub fn len(a: Int) -> Int {
  use <- bool.guard(a == 0, 1)
  let assert Ok(log10) = int.to_float(a) |> elementary.logarithm_10
  log10 |> float.truncate |> int.add(1)
}

pub fn split(n: Int, i: Int) -> List(Int) {
  let len = len(n)
  let prefix = n / pow(10, len - i)
  let suffix = n % pow(10, i)
  [prefix, suffix]
}

pub fn pow(a: Int, b: Int) -> Int {
  let assert Ok(result) = int.power(a, b |> int.to_float)
  assert_int(result)
}

pub fn concat(a: Int, b: Int) -> Int {
  let b_len = len(b)
  let multiplier = pow(10, b_len)
  a * multiplier + b
}

pub fn has_prefix(n: Int, prefix: Int) -> Bool {
  let n_len = len(n)
  let prefix_len = len(prefix)
  use <- bool.guard(n_len < prefix_len, False)
  let n_prefix = n / pow(10, n_len - prefix_len)
  n_prefix == prefix
}

pub fn strip_prefix(n: Int, prefix: Int) -> Int {
  use <- bool.guard(has_prefix(n, prefix), n)
  let prefix_len = len(prefix)
  n - prefix * pow(10, len(n) - prefix_len)
}

pub fn has_suffix(n: Int, suffix: Int) -> Bool {
  let n_len = len(n)
  let suffix_len = len(suffix)
  use <- bool.guard(n_len < suffix_len, False)
  let n_suffix = n % pow(10, suffix_len)
  n_suffix == suffix
}

pub fn strip_suffix(n: Int, suffix: Int) -> Int {
  use <- bool.guard(!has_suffix(n, suffix), n)
  let suffix_len = len(suffix)
  n / pow(10, suffix_len)
}

pub fn gcd(a: Int, b: Int) -> Int {
  case b {
    0 -> a
    _ -> gcd(b, a % b)
  }
}

pub fn pow_mod(base: Int, exponent: Int, modulus: Int) -> Int {
  case exponent {
    0 -> 1
    _ -> {
      let half = exponent / 2
      let square = pow_mod(base, half, modulus)
      let result = square * square % modulus
      case exponent % 2 {
        0 -> result
        _ -> result * base % modulus
      }
    }
  }
}

pub fn from_binary(binary: List(Bool)) {
  list.fold_right(binary, 0, fn(acc, bit) { acc * 2 + bool.to_int(bit) })
}

pub fn to_binary_string(n: Int) -> String {
  do_to_binary_string(n, 1)
}

fn do_to_binary_string(n: Int, mask: Int) -> String {
  case mask > n {
    True -> ""
    False -> {
      let bit = case int.bitwise_and(n, mask) != 0 {
        True -> "1"
        False -> "0"
      }
      let mask = int.bitwise_shift_left(mask, 1)
      do_to_binary_string(n, mask) <> bit
    }
  }
}
