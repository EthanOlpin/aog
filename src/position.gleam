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

pub const up = Position(-1, 0)

pub const down = Position(1, 0)

pub const left = Position(0, -1)

pub const right = Position(0, 1)

pub const up_left = Position(-1, -1)

pub const up_right = Position(-1, 1)

pub const down_left = Position(1, -1)

pub const down_right = Position(1, 1)

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

fn degrees(direction: Direction) {
  case direction {
    Right -> 0
    UpRight -> 45
    Up -> 90
    UpLeft -> 135
    Left -> 180
    DownLeft -> 225
    Down -> 270
    DownRight -> 315
  }
}

pub fn degree_delta(dir_a: Direction, dir_b: Direction) {
  let delta = int.absolute_value(degrees(dir_a) - degrees(dir_b))
  int.min(delta, 360 - delta)
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

pub fn rotate_left(direction: Direction) -> Direction {
  case direction {
    Up -> Left
    Left -> Down
    Down -> Right
    Right -> Up
    UpLeft -> DownLeft
    DownLeft -> DownRight
    DownRight -> UpRight
    UpRight -> UpLeft
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

pub fn diamond(center: Position, radius: Int) {
  let Position(row, col) = center
  list.unique({
    use ring_radius <- list.flat_map(list.range(2, radius))
    use delta_row <- list.flat_map(list.range(0, ring_radius))
    let delta_col = ring_radius - delta_row
    [
      Position(row + delta_row, col + delta_col),
      Position(row + delta_row, col - delta_col),
      Position(row - delta_row, col + delta_col),
      Position(row - delta_row, col - delta_col),
    ]
  })
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

pub fn negate(a: Position) -> Position {
  Position(-a.row, -a.col)
}

pub fn reduce(a: Position) -> Position {
  let g = num.gcd(a.row, a.col)
  Position(a.row / g, a.col / g)
}

pub fn distance(a: Position, b: Position) -> Int {
  let Position(row_diff, col_diff) = sub(a, b)
  int.absolute_value(row_diff) + int.absolute_value(col_diff)
}
