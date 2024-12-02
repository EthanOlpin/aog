import gleam/io
import gleam/result
import gleam/string
import simplifile

const logs_path = "logs"

pub fn any(data: a) -> a {
  let _ = simplifile.append(logs_path, string.inspect(data) <> "\n")
  io.debug(data)
}

pub fn if_error(data: Result(a, e)) -> Result(a, e) {
  result.map_error(data, any)
}
