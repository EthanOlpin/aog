import gleam/io
import gleam/option.{type Option}

pub fn idc(result: Result(a, b)) -> a {
  case result {
    Ok(x) -> x
    Error(error) -> {
      io.debug(error)
      panic as "idc"
    }
  }
}

pub fn idk(result: Option(a)) -> a {
  case result {
    option.Some(x) -> x
    option.None -> panic as "idk"
  }
}
