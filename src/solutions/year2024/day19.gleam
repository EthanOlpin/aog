import gleam/bool
import gleam/dict
import gleam/io
import gleam/list
import gleam/pair
import gleam/string
import input
import parse

fn drop_prefix(s, prefix) {
  case string.starts_with(s, prefix) {
    True -> string.drop_start(s, string.length(prefix))
    False -> s
  }
}

fn can_make(vocab, message: String) {
  can_make_with_memo(dict.new(), vocab, message) |> pair.second
}

fn can_make_with_memo(memo, vocab, message: String) {
  use <- bool.guard(message == "", #(memo, True))
  case dict.get(memo, message) {
    Ok(result) -> #(memo, result)
    Error(_) -> do_can_make_with_memo(memo, vocab, message)
  }
}

fn do_can_make_with_memo(memo, vocab, message: String) {
  let #(memo, result) =
    list.fold(vocab, #(memo, False), fn(acc, word) {
      let #(memo, result) = acc
      case !result && string.starts_with(message, word) {
        True -> drop_prefix(message, word) |> can_make_with_memo(memo, vocab, _)
        False -> #(memo, result)
      }
    })
  let memo = dict.insert(memo, message, result)
  #(memo, result)
}

fn count(vocab, message: String) {
  count_with_memo(dict.new(), vocab, message) |> pair.second
}

fn count_with_memo(memo, vocab, message: String) {
  use <- bool.guard(message == "", #(memo, 1))
  case dict.get(memo, message) {
    Ok(result) -> #(memo, result)
    Error(_) -> do_count_with_memo(memo, vocab, message)
  }
}

fn do_count_with_memo(memo, vocab, message: String) {
  let #(memo, result) =
    list.fold(vocab, #(memo, 0), fn(acc, word) {
      let #(memo, result) = acc
      case string.starts_with(message, word) {
        True ->
          drop_prefix(message, word)
          |> count_with_memo(memo, vocab, _)
          |> pair.map_second(fn(x) { x + result })
        False -> #(memo, result)
      }
    })
  let memo = dict.insert(memo, message, result)
  #(memo, result)
}

pub fn main() {
  let assert [vocab, messages] = input.get() |> parse.split("\n\n")
  let vocab = vocab |> parse.split(", ")
  let messages = messages |> parse.lines

  list.count(messages, can_make(vocab, _))
  |> io.debug

  list.fold(messages, 0, fn(total, message) { total + count(vocab, message) })
  |> io.debug
}
