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

pub type Direction {
  Up
  Down
  Left
  Right
  UpLeft
  UpRight
  DownLeft
  DownRight
}

const up = Position(-1, 0)

const down = Position(1, 0)

const left = Position(0, -1)

const right = Position(0, 1)

const up_left = Position(-1, -1)

const up_right = Position(-1, 1)

const down_left = Position(1, -1)

const down_right = Position(1, 1)

pub const all_directions = [
  Up,
  Down,
  Left,
  Right,
  UpLeft,
  UpRight,
  DownLeft,
  DownRight,
]

fn direction_to_delta(direction: Direction) -> Position {
  case direction {
    Up -> up
    Down -> down
    Left -> left
    Right -> right
    UpLeft -> up_left
    UpRight -> up_right
    DownLeft -> down_left
    DownRight -> down_right
  }
}

pub fn shift(pos: Position, direction: Direction) -> Position {
  add(pos, direction_to_delta(direction))
}

pub fn rotate_right(direction: Direction) -> Direction {
  case direction {
    Up -> Right
    Right -> Down
    Down -> Left
    Left -> Up
    UpLeft -> UpRight
    UpRight -> DownRight
    DownRight -> DownLeft
    DownLeft -> UpLeft
  }
}

pub fn ortho_neighbors(pos: Position) -> List(Position) {
  [shift(pos, Up), shift(pos, Down), shift(pos, Left), shift(pos, Right)]
}

pub fn diag_neighbors(pos: Position) -> List(Position) {
  [
    shift(pos, UpLeft),
    shift(pos, UpRight),
    shift(pos, DownLeft),
    shift(pos, DownRight),
  ]
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

pub fn sub(a: Position, b: Position) -> Position {
  Position(a.row - b.row, a.col - b.col)
}

pub fn add(a: Position, b: Position) -> Position {
  Position(a.row + b.row, a.col + b.col)
}
