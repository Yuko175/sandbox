import land_magic/types.{type Land, type Turn, Plains, Island, Swamp, Mountain, Forest, PlayerOne, PlayerTwo}

pub fn other_turn(turn: Turn) -> Turn {
  case turn {
    PlayerOne -> PlayerTwo
    PlayerTwo -> PlayerOne
  }
}

pub fn turn_name(turn: Turn) -> String {
  case turn {
    PlayerOne -> "プレイヤー1"
    PlayerTwo -> "プレイヤー2"
  }
}

pub fn land_name(land: Land) -> String {
  case land {
    Plains -> "平地"
    Island -> "島"
    Swamp -> "沼"
    Mountain -> "山"
    Forest -> "森"
  }
}

pub fn land_class(land: Land) -> String {
  case land {
    Plains -> "plains"
    Island -> "island"
    Swamp -> "swamp"
    Mountain -> "mountain"
    Forest -> "forest"
  }
}
