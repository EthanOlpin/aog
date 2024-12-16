import gleam/int
import gleam/io
import gleam/list
import gleam/set
import grid
import input
import parse

fn unique_destinations(target: Int, curr: grid.Cell(Int), grid: grid.Grid(Int)) {
  case curr.value {
    _ if curr.value != target -> set.new()
    9 -> set.new() |> set.insert(curr.position)
    _ ->
      grid.ortho_neighbors(grid, curr.position)
      |> list.map(unique_destinations(target + 1, _, grid))
      |> list.fold(set.new(), set.union)
  }
}

fn unique_path_count(target: Int, curr: grid.Cell(Int), grid: grid.Grid(Int)) {
  case curr.value {
    _ if curr.value != target -> 0
    9 -> 1
    _ ->
      grid.ortho_neighbors(grid, curr.position)
      |> list.map(unique_path_count(target + 1, _, grid))
      |> int.sum
  }
}

pub fn main() {
  let grid =
    input.get() |> parse.lines() |> list.map(parse.digits) |> grid.from_list

  let trailheads =
    grid.to_list(grid) |> list.filter(fn(cell) { cell.value == 0 })

  list.map(trailheads, unique_destinations(0, _, grid))
  |> list.fold(set.new(), set.union)
  |> set.size
  |> io.debug

  list.map(trailheads, unique_path_count(0, _, grid))
  |> int.sum
  |> io.debug
}
