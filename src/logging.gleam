import gleam/io
import gleam/string
import simplifile

const logs_path = "logs"

pub fn any(data: a) -> a {
  let _ =
    string.inspect(data)
    |> simplifile.append(logs_path, _)
  io.debug(data)
}

pub fn if_error(data: Result(a, e)) -> Result(a, e) {
  case data {
    Error(err) -> Error(any(err))
    _ -> data
  }
}
