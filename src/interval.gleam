import gleam/list

pub type Interval {
  Interval(low: Int, high: Int)
}

pub fn new(inclusive a: Int, exclusive b: Int) -> Interval {
  case b < a {
    False -> Interval(a, b)
    True -> Interval(b + 1, a + 1)
  }
}

pub fn size(interval: Interval) -> Int {
  interval.high - interval.low
}

pub fn range(interval: Interval) -> List(Int) {
  list.range(interval.low, interval.high - 1)
}
