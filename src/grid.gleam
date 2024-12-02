import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/yielder.{type Yielder}
import position.{type Position, Position}

pub type Grid(a) {
  Grid(width: Int, height: Int, wrapping: Bool, cells: Dict(Position, a))
}

pub type Cell(a) {
  Cell(position: Position, value: a)
}

pub fn from_list(xs: List(List(a))) -> Grid(a) {
  let row_count = list.length(xs)
  let cells =
    list.index_map(xs, fn(row, r) {
      list.index_map(row, fn(cell, c) { #(Position(r, c), cell) })
    })
    |> list.flatten
    |> dict.from_list
  let width = dict.size(cells) / row_count
  Grid(width:, height: row_count, wrapping: False, cells:)
}

pub fn to_wrapping(grid: Grid(a)) -> Grid(a) {
  Grid(..grid, wrapping: True)
}

pub fn has_position(grid: Grid(a), position: Position) -> Bool {
  dict.has_key(grid.cells, position)
}

pub fn normalize_position(grid: Grid(a), position: Position) -> Position {
  case grid.wrapping {
    True -> position.wrap(position, grid.width, grid.height)
    False -> position
  }
}

pub fn get(grid: Grid(a), position: Position) -> Result(a, Nil) {
  let position = normalize_position(grid, position)
  dict.get(grid.cells, position)
}

pub fn get_cell(grid: Grid(a), position: Position) -> Result(Cell(a), Nil) {
  let position = normalize_position(grid, position)
  use x <- result.try(get(grid, position))
  Ok(Cell(position, x))
}

pub fn up(grid: Grid(a), pos: Position) -> Result(Cell(a), Nil) {
  get_cell(grid, position.up(pos))
}

pub fn down(grid: Grid(a), pos: Position) -> Result(Cell(a), Nil) {
  get_cell(grid, position.down(pos))
}

pub fn left(grid: Grid(a), pos: Position) -> Result(Cell(a), Nil) {
  get_cell(grid, position.left(pos))
}

pub fn right(grid: Grid(a), pos: Position) -> Result(Cell(a), Nil) {
  get_cell(grid, position.right(pos))
}

pub fn ortho_neighbors(grid: Grid(a), pos: Position) -> List(Cell(a)) {
  position.ortho_neighbors(pos)
  |> list.filter_map(get_cell(grid, _))
}

pub fn diag_neighbors(grid: Grid(a), pos: Position) -> List(Cell(a)) {
  position.diag_neighbors(pos)
  |> list.filter_map(get_cell(grid, _))
}

pub fn all_neighbors(grid: Grid(a), pos: Position) -> List(Cell(a)) {
  position.all_neighbors(pos)
  |> list.filter_map(get_cell(grid, _))
}

pub fn cells(grid: Grid(a)) -> List(Cell(a)) {
  dict.to_list(grid.cells)
  |> list.map(fn(entry) { Cell(entry.0, entry.1) })
  |> list.sort(fn(a, b) { position.compare(a.position, b.position) })
}

pub fn iter_cells(grid: Grid(a)) -> Yielder(Cell(a)) {
  let cell_iter = yielder.from_list(cells(grid))
  case grid.wrapping {
    True -> yielder.cycle(cell_iter)
    False -> cell_iter
  }
}
