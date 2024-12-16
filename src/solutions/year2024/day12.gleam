import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/set.{type Set}
import grid.{type Cell, type Grid}
import input
import num
import parse
import position.{type Position, Position}

type Boundary {
  Boundary(in: Position, out: Position)
}

type Region {
  Region(positions: Set(Position), boundaries: Set(Boundary))
}

fn perimeter(region: Region) {
  region.boundaries |> set.size
}

fn area(region: Region) {
  region.positions |> set.size
}

type Side {
  Side(low: Boundary, high: Boundary)
}

fn sides(region: Region) {
  let #(row_boundaries, col_boundaries) =
    region.boundaries |> set.to_list |> list.partition(is_row_boundary)

  let horizontal =
    row_boundaries
    |> list.sort(fn(a, b) {
      int.compare(a.out.row, b.out.row)
      |> order.break_tie(int.compare(a.in.row, b.in.row))
      |> order.break_tie(int.compare(a.in.col, b.in.col))
    })
    |> list.map(fn(boundary) { Side(boundary, boundary) })
    |> coalesce(overlap_horizontal)

  let vertical =
    col_boundaries
    |> list.sort(fn(a, b) {
      int.compare(a.out.col, b.out.col)
      |> order.break_tie(int.compare(a.in.col, b.in.col))
      |> order.break_tie(int.compare(a.in.row, b.in.row))
    })
    |> list.map(fn(boundary) { Side(boundary, boundary) })
    |> coalesce(overlap_vertical)

  list.length(horizontal) + list.length(vertical)
}

fn overlap_horizontal(a: Side, b: Side) {
  a.high.in.row == b.high.in.row
  && a.high.out.row == b.high.out.row
  && num.diff(a.high.in.col, b.low.in.col) <= 1
}

fn overlap_vertical(a: Side, b: Side) {
  a.high.in.col == b.high.in.col
  && a.high.out.col == b.high.out.col
  && num.diff(a.high.in.row, b.low.in.row) <= 1
}

fn coalesce(sides: List(Side), overlap) {
  case sides {
    [a, b, ..rest] ->
      case overlap(a, b) {
        True -> coalesce([Side(a.low, b.high), ..rest], overlap)
        False -> [a, ..coalesce([b, ..rest], overlap)]
      }
    sides -> sides
  }
}

fn is_row_boundary(b: Boundary) {
  b.in.col == b.out.col
}

fn boundaries_at(cell: Cell(String), grid: Grid(String)) {
  position.ortho_neighbors(cell.position)
  |> list.filter(fn(neighbor_pos) {
    grid.get(grid, neighbor_pos) != Ok(cell.value)
  })
  |> list.map(fn(neighbor_pos) {
    Boundary(in: cell.position, out: neighbor_pos)
  })
  |> set.from_list
}

fn build_region(
  value: String,
  curr: Cell(String),
  grid: Grid(String),
  visited: Set(Position),
  region: Region,
) {
  let boundaries = set.union(region.boundaries, boundaries_at(curr, grid))
  let visited = set.insert(visited, curr.position)
  let positions = set.insert(region.positions, curr.position)
  let region = Region(positions:, boundaries:)
  grid.ortho_neighbors(grid, curr.position)
  |> list.filter(fn(neighbor) {
    neighbor.value == value && !set.contains(visited, neighbor.position)
  })
  |> list.fold(#(visited, region), fn(acc, neighbor) {
    let #(visited, region) = acc
    build_region(value, neighbor, grid, visited, region)
  })
}

fn make_regions(grid: Grid(String)) -> List(Region) {
  let #(_, regions) =
    list.fold(grid |> grid.to_list, #(set.new(), []), fn(acc, cell) {
      let #(visited, regions) = acc
      use <- bool.guard(set.contains(visited, cell.position), acc)
      let empty_region = Region(set.new(), set.new())
      let #(visited, region) =
        build_region(cell.value, cell, grid, visited, empty_region)
      case set.size(region.positions) == 0 {
        True -> #(visited, regions)
        False -> #(visited, [region, ..regions])
      }
    })
  regions
}

pub fn main() {
  let regions = input.get() |> parse.grid("\n", "") |> make_regions

  regions
  |> list.map(fn(region) { area(region) * perimeter(region) })
  |> int.sum
  |> io.debug

  regions
  |> list.map(fn(region) { area(region) * sides(region) })
  |> int.sum
  |> io.debug
}
