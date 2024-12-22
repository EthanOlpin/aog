import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import grid.{type Cell, type Grid}
import input
import parse
import position.{type Position, Position}

fn traverse(grid: Grid(String), curr: Cell(String), prev_pos: Position) {
  let next =
    grid.ortho_neighbors(grid, curr.position)
    |> list.find(fn(cell) { cell.value != "#" && cell.position != prev_pos })
  case next {
    Ok(next) -> {
      let #(distances, sub_path) = traverse(grid, next, curr.position)
      let assert Ok(next_dist) = dict.get(distances, next.position)
      let path = [curr.position, ..sub_path]
      #(dict.insert(distances, curr.position, next_dist + 1), path)
    }
    Error(Nil) -> #(dict.from_list([#(curr.position, 0)]), [curr.position])
  }
}

fn count_cheats(
  grid: Grid(String),
  dists_to_end: Dict(Position, Int),
  path: List(Position),
  of_duration cheat_radius: Int,
  by minimum: Int,
) {
  list.fold(path, 0, fn(acc, pos) {
    let assert Ok(original_dist) = dict.get(dists_to_end, pos)
    grid.diamond(grid, pos, cheat_radius)
    |> list.fold(acc, fn(total, neighbor) {
      let neighbor_pos = neighbor.position
      let dist_from_path = position.distance(neighbor_pos, pos)
      case dict.get(dists_to_end, neighbor_pos) {
        Ok(dist) if original_dist - dist >= minimum + dist_from_path ->
          total + 1
        _ -> total
      }
    })
  })
}

pub fn main() {
  let grid = input.get() |> parse.grid("\n", "")
  let assert Ok(start) = grid.find(grid, fn(cell) { cell.value == "S" })

  let #(dists_to_end, path) = traverse(grid, start, Position(row: -1, col: -1))

  count_cheats(grid, dists_to_end, path, of_duration: 2, by: 100)
  |> io.debug

  count_cheats(grid, dists_to_end, path, of_duration: 20, by: 100)
  |> io.debug
}
