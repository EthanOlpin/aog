import astar
import gleam/int
import gleam/io
import gleam/list
import gleam/set
import input
import parse
import position.{type Position, Position}

// const grid_width = 6

// const initial_obstacle_count = 12

const grid_width = 70

const initial_obstacle_count = 1024

fn path_len(start, end, obstacles) {
  let distance = astar.manhattan_distance(end)
  let can_reach = fn(pos: Position, distance) {
    pos.row >= 0
    && pos.row <= grid_width
    && pos.col >= 0
    && pos.col <= grid_width
    && distance < grid_width * grid_width
    && !set.contains(obstacles, pos)
  }
  let result =
    astar.search_one_with_filter(
      [start],
      fn(pos) { pos == end },
      position.ortho_neighbors,
      can_reach,
      distance,
    )
  case result {
    astar.Found(_, min_distance, _, _) -> Ok(min_distance)
    astar.NotFound -> Error(Nil)
  }
}

pub fn main() {
  let obstacles =
    input.get()
    |> parse.lines
    |> list.map(fn(line) {
      let assert [row, col] = line |> parse.ints
      Position(row, col)
    })

  let start = Position(0, 0)
  let end = Position(grid_width, grid_width)

  let #(first_obstacles, rest) = list.split(obstacles, initial_obstacle_count)

  let obstacle_set = first_obstacles |> set.from_list

  let assert Ok(len) = path_len(start, end, obstacle_set)
  io.debug(len)

  let assert Ok(breaking_coord) =
    list.fold_until(rest, Error(obstacle_set), fn(obstacles, new_obstacle) {
      let assert Error(obstacles) = obstacles
      let obstacle_set = set.insert(obstacles, new_obstacle)
      case path_len(start, end, obstacle_set) {
        Ok(_) -> list.Continue(Error(obstacle_set))
        Error(_) -> list.Stop(Ok(new_obstacle))
      }
    })

  let result =
    int.to_string(breaking_coord.row)
    <> ","
    <> int.to_string(breaking_coord.col)
  io.println(result)
}
