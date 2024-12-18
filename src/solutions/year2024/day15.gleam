import gleam/io
import gleam/list
import gleam/result
import gleam/string
import grid.{type Cell, type Grid}
import input
import parse
import position.{type Direction, type Position, Down, Left, Right, Up}

type Side {
  LeftSide
  RightSide
}

type BoxSize {
  Single
  Half(Side)
}

type Tile {
  Wall
  Box(BoxSize)
  Empty
}

fn get_other_half(grid: Grid(Tile), side: Side, box_cell: Cell(Tile)) {
  let extending_dir = case side {
    LeftSide -> Right
    RightSide -> Left
  }
  let assert Ok(other) = grid.cell_neighbor(grid, box_cell, extending_dir)
  other
}

fn push_box(
  grid: Grid(Tile),
  box_size: BoxSize,
  box_cell: Cell(Tile),
  direction: Direction,
) {
  case box_size, direction {
    Half(side), Up | Half(side), Down -> {
      use grid <- result.try(push_box_cell(grid, box_cell, direction))
      let other = get_other_half(grid, side, box_cell)
      push_box_cell(grid, other, direction)
    }
    _, _ -> push_box_cell(grid, box_cell, direction)
  }
}

fn push_box_cell(grid: Grid(Tile), box_cell: Cell(Tile), direction: Direction) {
  use next <- result.try(grid.cell_neighbor(grid, box_cell, direction))
  case next.value {
    Wall -> Error(Nil)
    Box(size) -> {
      use grid <- result.try(push_box(grid, size, next, direction))
      grid.update(grid, next.position, box_cell.value)
      |> grid.update(box_cell.position, Empty)
      |> Ok
    }
    Empty ->
      grid.update(grid, next.position, box_cell.value)
      |> grid.update(box_cell.position, Empty)
      |> Ok
  }
}

fn expand_grid(grid: Grid(Tile)) -> Grid(Tile) {
  grid.to_list(grid)
  |> list.flat_map(fn(cell) {
    case cell.value {
      Box(Single) -> [Box(Half(LeftSide)), Box(Half(RightSide))]
      Wall -> [Wall, Wall]
      Empty -> [Empty, Empty]
      _ -> panic
    }
  })
  |> list.sized_chunk(grid.cols(grid) * 2)
  |> grid.from_list
}

fn move(robot_position: Position, grid: Grid(Tile), direction: Direction) {
  use cell <- result.try(grid.get_cell(grid, robot_position))
  use next <- result.try(grid.cell_neighbor(grid, cell, direction))
  case next.value {
    Wall -> Error(Nil)
    Box(box) -> {
      use updated_grid <- result.try(push_box(grid, box, next, direction))
      Ok(#(next.position, updated_grid))
    }
    Empty -> Ok(#(next.position, grid))
  }
}

fn traverse(
  robot_position: Position,
  grid: Grid(Tile),
  movements: List(Direction),
) {
  case movements {
    [] -> grid
    [direction, ..rest] ->
      case move(robot_position, grid, direction) {
        Ok(#(new_position, new_grid)) -> traverse(new_position, new_grid, rest)
        Error(_) -> traverse(robot_position, grid, rest)
      }
  }
}

fn score(grid: Grid(Tile)) {
  use acc, cell <- list.fold(grid.to_list(grid), 0)
  let position.Position(row, col) = cell.position
  case cell.value {
    Box(Half(LeftSide)) | Box(Single) -> acc + 100 * row + col
    _ -> acc
  }
}

fn parse_direction(dir: String) -> Direction {
  case dir {
    "^" -> Up
    "v" -> Down
    "<" -> Left
    ">" -> Right
    _ -> panic
  }
}

fn parse_grid(grid_str: String) -> #(Position, Grid(Tile)) {
  let raw_grid = parse.grid(grid_str, "\n", "")
  let assert Ok(grid.Cell(start_pos, _)) =
    grid.find(raw_grid, fn(cell) {
      case cell.value {
        "@" -> True
        _ -> False
      }
    })
  let grid = grid.update(raw_grid, start_pos, ".")
  #(start_pos, grid.map(grid, fn(cell) { parse_tile(cell.value) }))
}

fn parse_tile(tile: String) -> Tile {
  case tile {
    "#" -> Wall
    "[" -> Box(Half(LeftSide))
    "]" -> Box(Half(RightSide))
    "O" -> Box(Single)
    "." -> Empty
    _ -> panic
  }
}

pub fn main() {
  let assert [grid, movements] = input.get() |> string.split("\n\n")
  let #(start_pos, grid) = parse_grid(grid)
  let directions =
    string.split(movements, "\n")
    |> list.map(string.split(_, ""))
    |> list.flat_map(list.map(_, parse_direction))

  traverse(start_pos, grid, directions) |> score |> io.debug

  let start_pos = position.Position(start_pos.row, start_pos.col * 2)
  traverse(start_pos, expand_grid(grid), directions) |> score |> io.debug
}
