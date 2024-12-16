import defaultdict.{type Counter}
import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/string
import input
import parse
import position.{type Position, Position}

type Robot {
  Robot(pos: Position, vel: Position)
}

const width = 101

const height = 103

type Quadrant {
  TopLeft
  TopRight
  BottomLeft
  BottomRight
  Edge
}

fn quadrant_counts(robots: List(Robot)) -> Counter(Quadrant) {
  list.map(robots, fn(robot) {
    let Position(row, col) = robot.pos
    let mid_col = { width - 1 } / 2
    let mid_row = { height - 1 } / 2
    case int.compare(row, mid_row), int.compare(col, mid_col) {
      order.Lt, order.Lt -> TopLeft
      order.Gt, order.Lt -> BottomLeft
      order.Lt, order.Gt -> TopRight
      order.Gt, order.Gt -> BottomRight
      _, _ -> Edge
    }
  })
  |> list.filter(fn(quadrant) { quadrant != Edge })
  |> defaultdict.counter_from_list
}

fn swag(quadrant_counts: Counter(Quadrant)) -> Float {
  let total = defaultdict.values(quadrant_counts) |> int.sum
  let expected = int.to_float(total) /. 4.0
  let squared_diffs =
    defaultdict.values(quadrant_counts)
    |> list.map(fn(count) {
      let diff = int.to_float(count) -. expected
      diff *. diff
    })
  squared_diffs |> float.sum
}

fn step(robot: Robot) -> Robot {
  let pos =
    position.add(robot.pos, robot.vel)
    |> position.wrap(width, height)
  Robot(..robot, pos:)
}

fn step_all(robots: List(Robot)) -> List(Robot) {
  list.map(robots, step)
}

fn step_all_n(robots: List(Robot), n: Int) -> List(Robot) {
  list.range(0, n - 1) |> list.fold(robots, fn(robots, _) { step_all(robots) })
}

fn find_easter_egg(robots: List(Robot), i: Int, swag_threshold: Float) -> Int {
  let step_n = step_all(robots)
  let counts = quadrant_counts(step_n)
  let swag = swag(counts)
  use <- bool.guard(swag >. swag_threshold, i)
  find_easter_egg(step_n, i + 1, swag_threshold)
}

pub fn main() {
  let robots =
    input.get()
    |> parse.lines()
    |> list.map(fn(line) {
      let assert [c, r, vc, vr] = line |> parse.ints()
      Robot(pos: Position(r, c), vel: Position(vr, vc))
    })

  robots
  |> step_all_n(100)
  |> quadrant_counts
  |> defaultdict.values
  |> int.product
  |> io.debug

  robots
  |> find_easter_egg(1, 20_000.0)
  |> int.to_string
  |> string.append("?")
  |> io.println
}
