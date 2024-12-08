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
  sleep(1000)
  io.debug(a)
}
