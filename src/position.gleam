import gleam/int
import gleam/list
import gleam/order
import num

pub type Position {
  Position(row: Int, col: Int)
}

pub fn wrap(pos: Position, width: Int, height: Int) -> Position {
  let row = num.wrap_index(pos.row, height)
  let col = num.wrap_index(pos.col, width)
  Position(row:, col:)
}

pub fn up(pos: Position) -> Position {
  Position(pos.row - 1, pos.col)
}

pub fn down(pos: Position) -> Position {
  Position(pos.row + 1, pos.col)
}

pub fn left(pos: Position) -> Position {
  Position(pos.row, pos.col - 1)
}

pub fn right(pos: Position) -> Position {
  Position(pos.row, pos.col + 1)
}

pub fn ortho_neighbors(pos: Position) -> List(Position) {
  [up(pos), down(pos), left(pos), right(pos)]
}

pub fn diag_neighbors(pos: Position) -> List(Position) {
  [up(left(pos)), up(right(pos)), down(left(pos)), down(right(pos))]
}

pub fn all_neighbors(pos: Position) -> List(Position) {
  list.append(ortho_neighbors(pos), diag_neighbors(pos))
}

pub fn compare(a: Position, b: Position) -> order.Order {
  case int.compare(a.row, b.row) {
    order.Eq -> int.compare(a.col, b.col)
    x -> x
  }
}
