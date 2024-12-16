import gleam/int
import gleam/io
import gleam/list
import input
import interval
import interval_tree
import parse

fn make_tree(digits) {
  do_make_tree(digits, 0, 0, []) |> interval_tree.from_list
}

fn do_make_tree(digits, start, index, acc) {
  case digits {
    [block_size, free_space, ..rest] -> {
      let block = #(interval.new(start, start + block_size), index)
      let next_start = start + block_size + free_space
      do_make_tree(rest, next_start, index + 1, [block, ..acc])
    }
    [block_size] -> {
      let block = #(interval.new(start, start + block_size), index)
      [block, ..acc]
    }
    [] -> acc
  }
}

pub fn fragmenting_compact(tree) {
  let assert Ok(upper_bound) = interval_tree.upper_bound(tree)
  do_fragmenting_compact(tree, upper_bound)
}

fn do_fragmenting_compact(tree, upper_bound) {
  let assert Ok(#(popped, #(last_interval, last_id))) =
    tree |> interval_tree.pop_last
  let last_size = interval.size(last_interval)
  let compacted =
    interval_tree.disperse_sized(popped, last_id, last_size, 0, upper_bound)
  case compacted {
    Ok(compacted) -> {
      let assert Ok(new_upper_bound) = interval_tree.upper_bound(compacted)
      case new_upper_bound < upper_bound {
        True -> do_fragmenting_compact(compacted, new_upper_bound)
        False -> compacted
      }
    }
    Error(_) -> tree
  }
}

pub fn compact(tree) {
  case tree |> interval_tree.pop_last {
    Ok(#(popped, #(last_interval, last_id))) -> {
      let last_size = interval.size(last_interval)
      let compacted =
        interval_tree.insert_sized(
          popped,
          last_id,
          last_size,
          0,
          last_interval.low,
        )
      case compacted {
        Ok(compacted) -> compact(compacted)
        Error(_) ->
          compact(popped) |> interval_tree.insert(last_interval, last_id)
      }
    }
    Error(_) -> tree
  }
}

fn checksum(tree) {
  interval_tree.in_order(tree)
  |> list.flat_map(fn(node) {
    let #(interval, id) = node
    interval.range(interval) |> list.map(int.multiply(_, id))
  })
  |> int.sum
}

pub fn main() {
  let tree = input.get() |> parse.digits |> make_tree
  fragmenting_compact(tree) |> checksum |> io.debug
  compact(tree) |> checksum |> io.debug
}
