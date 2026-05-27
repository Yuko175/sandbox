import land_magic/model/types.{type Land, type Turn, Plains, Island, Swamp, Mountain, Forest, PlayerOne, PlayerTwo}

/// 概要: 今の手番の相手を返します。
/// 引数: `turn` に現在の手番を渡します。
/// 戻り値: `PlayerOne` と `PlayerTwo` を入れ替えた手番を返します。
pub fn other_turn(turn: Turn) -> Turn {
  case turn {
    PlayerOne -> PlayerTwo
    PlayerTwo -> PlayerOne
  }
}

/// 概要: 手番を画面表示用の名前に変換します。
/// 引数: `turn` に表示したい手番を渡します。
/// 戻り値: 「プレイヤー1」「プレイヤー2」のどちらかを返します。
pub fn turn_name(turn: Turn) -> String {
  case turn {
    PlayerOne -> "プレイヤー1"
    PlayerTwo -> "プレイヤー2"
  }
}

/// 概要: カードの種類を日本語名に変換します。
/// 引数: `land` に土地カードの種類を渡します。
/// 戻り値: カード名の文字列を返します。
pub fn land_name(land: Land) -> String {
  case land {
    Plains -> "平地"
    Island -> "島"
    Swamp -> "沼"
    Mountain -> "山"
    Forest -> "森"
  }
}

/// 概要: カードの種類を CSS クラス名に変換します。
/// 引数: `land` に土地カードの種類を渡します。
/// 戻り値: 画面表示で使うクラス名を返します。
pub fn land_class(land: Land) -> String {
  case land {
    Plains -> "plains"
    Island -> "island"
    Swamp -> "swamp"
    Mountain -> "mountain"
    Forest -> "forest"
  }
}