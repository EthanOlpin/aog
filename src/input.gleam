import argv
import simplifile

fn read_input_path_arg() {
  let assert [path] = argv.load().arguments
  path
}

fn read(path: String) -> String {
  let assert Ok(content) = simplifile.read(path)
  content
}

pub fn get() {
  read_input_path_arg() |> read
}
