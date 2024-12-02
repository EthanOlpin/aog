import argv
import birl
import clip
import clip/opt
import envoy
import gleam/http/request
import gleam/http/response.{Response}
import gleam/httpc
import gleam/int
import gleam/io
import gleam/string
import shellout
import simplifile

const aoc_base_url = "https://adventofcode.com"

fn aoc_session_id() {
  let assert Ok(session_id) = envoy.get("AOC_SESSION_ID")
  session_id
}

fn fetch_input(year: String, day: String) -> String {
  let uri = "/" <> year <> "/day/" <> day <> "/input"
  let assert Ok(request) = request.to(aoc_base_url <> uri)
  let request = request.set_cookie(request, "session", aoc_session_id())
  let assert Ok(Response(200, _, body)) = httpc.send(request)
  body |> string.trim
}

fn cache_input(year: String, day: String, input: String) -> Nil {
  let assert Ok(_) = simplifile.create_directory_all("inputs/" <> year <> "/")
  let assert Ok(_) = simplifile.write("inputs/" <> year <> "/" <> day, input)
  Nil
}

fn ensure_input(year: String, day: String) -> Result(String, Nil) {
  let path = "inputs/" <> year <> "/" <> day
  case simplifile.is_file(path) {
    Ok(True) -> Nil
    _ -> fetch_input(year, day) |> cache_input(year, day, _)
  }
  Ok(path)
}

fn year_day_eastern_time() {
  let assert Ok(now) = birl.now_with_timezone("America/New_York")
  let birl.Day(year, _, day) = birl.get_day(now)
  #(year |> int.to_string, day |> int.to_string)
}

fn command() {
  let #(today_year, today_day) = year_day_eastern_time()
  clip.command({
    use year <- clip.parameter
    use day <- clip.parameter
    #(year, day)
  })
  |> clip.opt(opt.new("year") |> opt.default(today_year))
  |> clip.opt(opt.new("day") |> opt.default(today_day))
  |> clip.run(argv.load().arguments)
}

pub fn main() {
  let assert Ok(#(year, day)) = command()
  let assert Ok(input_path) = ensure_input(year, day)
  io.println(
    "\nRunning solution for year " <> year <> " day " <> day <> "...\n",
  )
  let solution_path = "solutions/year" <> year <> "/day" <> day
  shellout.command(
    run: "gleam",
    with: ["run", "-m", solution_path, "--", input_path],
    in: ".",
    opt: [shellout.LetBeStdout],
  )
}
