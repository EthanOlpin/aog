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
