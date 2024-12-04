import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import grid.{type Cell, type Grid}
import input
import parse
import position

fn is_x_mas(grid: Grid(String), curr: Cell(String)) {
  use <- bool.guard(curr.value != "A", False)
  let diag_values =
    grid.diag_neighbors(grid, curr.position) |> list.map(grid.cell_value)
  case diag_values {
    ["M", "S", "M", "S"]
    | ["S", "M", "S", "M"]
    | ["M", "M", "S", "S"]
    | ["S", "S", "M", "M"] -> True
    _ -> False
  }
}

fn count_xmases_out_of(grid: Grid(String), curr: Cell(String)) {
  use <- bool.guard(curr.value != "X", 0)
  position.all_directions
  |> list.map(fn(direction) {
    grid.offshoot(grid, curr, direction, 3)
    |> list.map(grid.cell_value)
  })
  |> list.count(fn(offshoot) { offshoot == ["M", "A", "S"] })
}

pub fn main() {
  let grid = input.get() |> parse.grid("\n", "")

  grid.to_list(grid)
  |> list.map(count_xmases_out_of(grid, _))
  |> int.sum
  |> io.debug

  grid.to_list(grid) |> list.count(is_x_mas(grid, _)) |> io.debug
}
