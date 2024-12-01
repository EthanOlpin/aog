import gleam/http/request
import gleam/httpc
import gleam/result
import logging
import simplifile

//const base_url = "https://adventofcode.com/"

pub fn fetch(year: String, day: String) -> String {
  todo
  // let path = "/" <> year <> "/day/" <> day <> "/input"
  // let assert Ok(req) = request.to(base_url <> path) |> logging.debug_when_error
  // let assert Ok(resp) = httpc.send(req) |> logging.debug_when_error
  // resp.body
}

pub fn read(year: String, day: String) -> Result(String, Nil) {
  let path = "inputs/" <> year <> "/" <> day
  simplifile.read(path) |> logging.if_error |> result.replace_error(Nil)
}

pub fn get() {
  let year = "2024"
  let day = "1"
  result.unwrap(read(year, day), fetch(year, day))
}
