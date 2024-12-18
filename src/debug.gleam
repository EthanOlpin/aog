import gleam/io
import gleam/option.{type Option}

pub fn idc(result: Result(a, b)) -> a {
  let assert Ok(x) = result
  x
}

pub fn idk(result: Option(a)) -> a {
  let assert option.Some(x) = result
  x
}

pub fn die() -> Nil {
  panic as "r.i.p."
}

@external(erlang, "timer", "sleep")
pub fn sleep(ms: Int) -> Nil

pub fn slow_print(a) -> a {
  io.debug(a)
  sleep(1000)
  a
}

pub fn print_if(a, b: Bool) -> Nil {
  case b {
    True -> {
      io.debug(a)
      Nil
    }
    False -> Nil
  }
}
