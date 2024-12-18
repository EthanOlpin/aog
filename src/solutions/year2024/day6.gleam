import gleam/bool
import gleam/io
import gleam/list
import gleam/set.{type Set}
import grid.{type Cell, type Grid, Cell}
import input
import parse
import position.{type Direction, Down, Left, Right, Up}

type Step {
  Exit
  Next(Cell(String), Direction)
}

fn step(grid: Grid(String), cell: Cell(String), direction: Direction) {
  case grid.cell_neighbor(grid, cell, direction) {
    Ok(Cell(_, value: "#")) ->
      step(grid, cell, position.rotate_right(direction))
    Ok(cell) -> Next(cell, direction)
    Error(_) -> Exit
  }
}

fn traverse(
  grid: Grid(String),
  path: Set(Cell(String)),
  cell: Cell(String),
  direction: Direction,
) -> Set(Cell(String)) {
  let path = set.insert(path, cell)
  case step(grid, cell, direction) {
    Next(next, direction) -> traverse(grid, path, next, direction)
    Exit -> path
  }
}

fn detect_cycle(
  grid: Grid(String),
  path: Set(#(Cell(String), Direction)),
  cell: Cell(String),
  direction: Direction,
) -> Bool {
  use <- bool.guard(set.contains(path, #(cell, direction)), True)
  let path = set.insert(path, #(cell, direction))
  case step(grid, cell, direction) {
    Next(next, direction) -> detect_cycle(grid, path, next, direction)
    Exit -> False
  }
}

fn match_start(cell: Cell(String)) {
  case cell.value {
    "^" -> Ok(#(cell, Up))
    "<" -> Ok(#(cell, Left))
    ">" -> Ok(#(cell, Right))
    "v" -> Ok(#(cell, Down))
    _ -> Error(Nil)
  }
}

pub fn main() {
  let grid = input.get() |> parse.grid("\n", "")

  let cells = grid.to_list(grid)

  let assert Ok(#(start, direction)) = cells |> list.find_map(match_start)

  let path = traverse(grid, set.new(), start, direction)

  path |> set.size |> io.debug

  path
  |> set.to_list
  |> list.count(fn(c) {
    let grid = grid.update(grid, c.position, "#")
    detect_cycle(grid, set.new(), start, direction)
  })
  |> io.debug
}
