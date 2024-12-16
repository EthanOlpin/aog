import position

pub const up = "↑"

pub const down = "↓"

pub const left = "←"

pub const right = "→"

pub const up_left = "↖"

pub const up_right = "↗"

pub const down_left = "↙"

pub const down_right = "↘"

pub const solid = "█"

pub const light = "░"

pub const medium = "▒"

pub const dark = "▓"

pub fn for_direction(direction: position.Direction) -> String {
  case direction {
    position.Up -> up
    position.Down -> down
    position.Left -> left
    position.Right -> right
    position.UpLeft -> up_left
    position.UpRight -> up_right
    position.DownLeft -> down_left
    position.DownRight -> down_right
  }
}
