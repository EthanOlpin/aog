import astar.{Found}
import gleam/bool
import gleam/io
import gleam/list
import gleam/set
import grid.{type Grid}
import input
import parse
import position

type Node {
  Node(position: position.Position, heading: position.Direction)
}

const wall = "#"

const end = "E"

const start = "S"

fn neighbors(node: Node, grid: Grid(String)) {
  let left = position.rotate_left(node.heading)
  let right = position.rotate_right(node.heading)
  let neighbor_dirs = [left, node.heading, right]
  use dir <- list.filter_map(neighbor_dirs)
  case grid.neighbor(grid, node.position, dir) {
    Ok(neighbor) if neighbor.value == wall -> Error(Nil)
    Ok(neighbor) -> Ok(Node(neighbor.position, dir))
    Error(Nil) -> Error(Nil)
  }
}

fn distance(from: Node, to: Node) {
  let distance = position.distance(from.position, to.position)
  let rotations = position.degree_delta(from.heading, to.heading) / 90
  distance + 1000 * rotations
}

fn estimate_distance(from: Node, to: position.Position) {
  let pos = from.position
  let distance = position.distance(pos, to)
  let rotation = bool.to_int(pos.row != to.row && pos.col != to.col)
  distance + rotation * 1000
}

fn search(start: Node, end: grid.Cell(String), grid) {
  let distance =
    astar.int_distance(distance, estimate_distance(_, end.position))
  astar.search_all(
    [start],
    fn(node) { node.position == end.position },
    neighbors(_, grid),
    distance,
  )
}

pub fn main() {
  let grid = input.get() |> parse.grid("\n", "")
  let assert Ok(start) = grid.find(grid, fn(cell) { cell.value == start })
  let assert Ok(end) = grid.find(grid, fn(cell) { cell.value == end })
  let start = Node(start.position, heading: position.Right)
  let assert Found(_, min_distance, _, _) as result = search(start, end, grid)

  min_distance |> io.debug

  astar.all_states_on_paths(result)
  |> set.map(fn(node) { node.position })
  |> set.size
  |> io.debug
}
