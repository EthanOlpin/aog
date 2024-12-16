import gleam/int
import gleam/list
import gleam/order
import gleam/result
import interval.{type Interval, Interval}

pub type IntervalTree(a) {
  Empty
  IntervalTree(
    val: a,
    min: Int,
    max: Int,
    left: IntervalTree(a),
    interval: Interval,
    right: IntervalTree(a),
  )
}

pub fn one(interval: Interval, val: a) {
  IntervalTree(val, interval.low, interval.high, Empty, interval, Empty)
}

fn halve_list(list: List(a)) -> #(List(a), List(a)) {
  do_halve_list(list, list, [])
}

fn do_halve_list(
  slow: List(a),
  fast: List(a),
  acc: List(a),
) -> #(List(a), List(a)) {
  case slow {
    [] -> #(list.reverse(acc), fast)
    [slow_first, ..slow_rest] ->
      case fast {
        [] -> #(list.reverse(acc), slow)
        [_] -> #(list.reverse(acc), slow)
        [_, _, ..rest] -> do_halve_list(slow_rest, rest, [slow_first, ..acc])
      }
  }
}

fn pop_middle(list: List(a)) -> Result(#(List(a), a, List(a)), Nil) {
  case halve_list(list) {
    #(left, [middle, ..right]) -> Ok(#(left, middle, right))
    _ -> Error(Nil)
  }
}

fn compare_start(a: Interval, b: Interval) -> order.Order {
  case int.compare(a.low, b.low) {
    order.Eq -> int.compare(a.high, b.high)
    result -> result
  }
}

pub fn from_list(intervals: List(#(Interval, a))) {
  let intervals =
    list.sort(intervals, fn(pair1, pair2) { compare_start(pair1.0, pair2.0) })

  case pop_middle(intervals) {
    Ok(#(left, #(interval, val), right)) -> {
      let left = from_list(left)
      let right = from_list(right)
      let min = lower_bound(left) |> result.unwrap(interval.low)
      let max = upper_bound(right) |> result.unwrap(interval.high)
      IntervalTree(val:, min:, max:, left:, interval:, right:)
    }
    Error(_) -> Empty
  }
}

pub fn in_order(tree: IntervalTree(a)) -> List(#(Interval, a)) {
  do_in_order(tree, []) |> list.reverse
}

fn do_in_order(
  tree: IntervalTree(a),
  acc: List(#(Interval, a)),
) -> List(#(Interval, a)) {
  case tree {
    Empty -> acc
    IntervalTree(a, _, _, left:, interval:, right:) -> {
      let acc = do_in_order(left, acc)
      let acc = [#(interval, a), ..acc]
      do_in_order(right, acc)
    }
  }
}

pub fn pop_last(
  tree: IntervalTree(a),
) -> Result(#(IntervalTree(a), #(Interval, a)), Nil) {
  case tree {
    Empty -> Error(Nil)
    IntervalTree(a, _, _, left:, interval:, right:) -> {
      case pop_last(right) {
        Ok(#(new_right, last)) -> {
          let max = upper_bound(new_right) |> result.unwrap(interval.high)
          Ok(#(IntervalTree(..tree, max:, right: new_right), last))
        }
        Error(_) -> Ok(#(left, #(interval, a)))
      }
    }
  }
}

pub fn insert(
  tree: IntervalTree(a),
  interval: Interval,
  val: a,
) -> IntervalTree(a) {
  case tree {
    Empty -> one(interval, val)
    IntervalTree(_, _, _, left, exiting_interval, right) -> {
      case compare_start(interval, exiting_interval) {
        order.Lt -> {
          let left = insert(left, interval, val)
          let min = lower_bound(left) |> result.unwrap(interval.low)
          IntervalTree(..tree, min:, left:)
        }
        _ -> {
          let right = insert(right, interval, val)
          let max = upper_bound(right) |> result.unwrap(interval.high)
          IntervalTree(..tree, max:, right:)
        }
      }
    }
  }
}

pub fn insert_sized(
  tree: IntervalTree(a),
  val: a,
  size: Int,
  start: Int,
  end: Int,
) -> Result(IntervalTree(a), Nil) {
  case tree {
    _ if start >= end -> Error(Nil)
    Empty -> {
      let interval = Interval(start, start + size)
      case int.compare(end - start, size) {
        order.Lt -> Error(Nil)
        _ -> Ok(one(interval, val))
      }
    }
    IntervalTree(_, _, _, left, interval, right) -> {
      case insert_sized(left, val, size, start, interval.low) {
        Error(_) -> {
          case insert_sized(right, val, size, interval.high, end) {
            Error(_) -> Error(Nil)
            Ok(right) -> {
              let max = upper_bound(right) |> result.unwrap(interval.high)
              Ok(IntervalTree(..tree, max:, right:))
            }
          }
        }
        Ok(left) -> {
          let min = lower_bound(left) |> result.unwrap(interval.low)
          Ok(IntervalTree(..tree, min:, left:))
        }
      }
    }
  }
}

pub fn disperse_sized(
  tree: IntervalTree(a),
  val: a,
  size: Int,
  start: Int,
  end: Int,
) -> Result(IntervalTree(a), Nil) {
  let #(inserted, new_tree) = do_disperse_sized(tree, val, size, start, end)
  case inserted == size {
    True -> Ok(new_tree)
    False -> Error(Nil)
  }
}

fn do_disperse_sized(
  tree: IntervalTree(a),
  val: a,
  size: Int,
  start: Int,
  end: Int,
) -> #(Int, IntervalTree(a)) {
  case tree {
    _ if start >= end -> #(0, tree)
    _ if size <= 0 -> #(0, tree)
    Empty -> {
      let interval = Interval(start, int.min(start + size, end))
      let new_tree = one(interval, val)
      #(interval.size(interval), new_tree)
    }
    IntervalTree(_, _, _, left, interval, right) -> {
      let #(inserted_left, left) =
        do_disperse_sized(left, val, size, start, interval.low)
      let #(inserted_right, right) =
        do_disperse_sized(right, val, size - inserted_left, interval.high, end)
      let min = lower_bound(left) |> result.unwrap(interval.low)
      let max = upper_bound(right) |> result.unwrap(interval.high)
      let new_tree = IntervalTree(..tree, min:, max:, left:, interval:, right:)
      #(inserted_left + inserted_right, new_tree)
    }
  }
}

pub fn lower_bound(tree: IntervalTree(a)) -> Result(Int, Nil) {
  case tree {
    Empty -> Error(Nil)
    IntervalTree(_, min, _, _, _, _) -> Ok(min)
  }
}

pub fn upper_bound(tree: IntervalTree(a)) -> Result(Int, Nil) {
  case tree {
    Empty -> Error(Nil)
    IntervalTree(_, _, max, _, _, _) -> Ok(max)
  }
}
