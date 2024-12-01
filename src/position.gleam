import gleam/list

pub type Position {
  Position(row: Int, col: Int)
}

pub fn wrap(position: Position, width: Int, height: Int) -> Position {
  let Position(row, col) = position
  let row = case row {
    r if r >= height -> r % height
    r if r < 0 -> height + r % height
    r -> r
  }
  let col = case col {
    c if c >= width -> c % width
    c if c < 0 -> width + c % width
    c -> c
  }
  Position(row, col)
}

pub fn up(position: Position) -> Position {
  Position(position.row - 1, position.col)
}

pub fn down(position: Position) -> Position {
  Position(position.row + 1, position.col)
}

pub fn left(position: Position) -> Position {
  Position(position.row, position.col - 1)
}

pub fn right(position: Position) -> Position {
  Position(position.row, position.col + 1)
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
