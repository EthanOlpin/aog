import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import gleam/string
import position.{type Position, Position}

pub type Grid(a) {
  Grid(width: Int, height: Int, wrapping: Bool, cells: Dict(Position, a))
}

pub type Cell(a) {
  Cell(position: Position, value: a)
}

pub fn parse(input: String) -> Grid(String) {
  let rows =
    string.split(input, "\n")
    |> list.index_map(parse_row)

  let assert Ok(first_row) = list.first(rows)
  let width = dict.size(first_row)
  let cells = list.fold(rows, dict.new(), dict.merge)
  let height = dict.size(cells) / width
  Grid(width:, height:, wrapping: False, cells:)
}

pub fn to_wrapping(grid: Grid(a)) -> Grid(a) {
  Grid(..grid, wrapping: True)
}

fn parse_row(row: String, col_index: Int) -> Dict(Position, String) {
  string.to_graphemes(row)
  |> list.index_map(fn(c, row_index) { #(Position(row_index, col_index), c) })
  |> dict.from_list
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
