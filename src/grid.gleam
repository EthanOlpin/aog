import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder.{type Yielder}
import position.{type Direction, type Position, Position}

pub opaque type Grid(a) {
  Grid(width: Int, height: Int, wrapping: Bool, cells: Dict(Position, a))
}

pub type Cell(a) {
  Cell(position: Position, value: a)
}

pub fn rows(grid: Grid(a)) -> Int {
  grid.height
}

pub fn cols(grid: Grid(a)) -> Int {
  grid.width
}

pub fn from_list(xs: List(List(a))) -> Grid(a) {
  let row_count = list.length(xs)
  let cells =
    {
      use row, r <- list.index_map(xs)
      use cell, c <- list.index_map(row)
      #(Position(r, c), cell)
    }
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

pub fn update(grid: Grid(a), position: Position, value: a) -> Grid(a) {
  let position = normalize_position(grid, position)
  let cells = dict.insert(grid.cells, position, value)
  Grid(..grid, cells:)
}

pub fn neighbor(
  grid: Grid(a),
  cell: Cell(a),
  direction: Direction,
) -> Result(Cell(a), Nil) {
  let next = position.shift(cell.position, direction)
  get_cell(grid, next)
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

pub fn to_list(grid: Grid(a)) -> List(Cell(a)) {
  dict.to_list(grid.cells)
  |> list.map(fn(entry) { Cell(entry.0, entry.1) })
  |> list.sort(fn(a, b) { position.compare(a.position, b.position) })
}

pub fn iter_cells(grid: Grid(a)) -> Yielder(Cell(a)) {
  let cell_iter = yielder.from_list(to_list(grid))
  case grid.wrapping {
    True -> yielder.cycle(cell_iter)
    False -> cell_iter
  }
}

pub fn cell_value(cell: Cell(a)) -> a {
  cell.value
}

pub fn offshoot(
  grid: Grid(a),
  from: Cell(a),
  dir: Direction,
  size: Int,
) -> List(Cell(a)) {
  case neighbor(grid, from, dir) {
    Ok(cell) if size > 0 -> [cell, ..offshoot(grid, cell, dir, size - 1)]
    _ -> []
  }
}

pub fn find(grid: Grid(a), pred: fn(Cell(a)) -> Bool) -> Result(Cell(a), Nil) {
  iter_cells(grid)
  |> yielder.find(fn(cell) { pred(cell) })
}

pub fn map(grid: Grid(a), f: fn(Cell(a)) -> b) -> Grid(b) {
  let cells = dict.map_values(grid.cells, fn(pos, val) { f(Cell(pos, val)) })
  Grid(
    width: grid.width,
    height: grid.height,
    wrapping: grid.wrapping,
    cells: cells,
  )
}

pub fn display(grid: Grid(a), cell_to_string: fn(Cell(a)) -> String) -> String {
  to_list(grid)
  |> list.map(cell_to_string)
  |> list.sized_chunk(cols(grid))
  |> list.map(string.join(_, ""))
  |> string.join("\n")
}

pub fn display_strings(grid: Grid(String)) -> String {
  display(grid, fn(cell) { cell.value })
}
