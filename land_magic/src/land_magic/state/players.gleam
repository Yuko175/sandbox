import land_magic/model/domain.{other_turn}
import land_magic/model/types.{type Model, type Player, type Turn, PlayerOne, PlayerTwo, Model}

/// 概要: 現在の手番のプレイヤーを取り出します。
/// 引数: `model` にゲーム全体の状態を渡します。
/// 戻り値: 現在操作中のプレイヤーを返します。
pub fn current_player(model: Model) -> Player {
  player_by_turn(model, model.turn)
}

/// 概要: 現在の手番の相手プレイヤーを取り出します。
/// 引数: `model` にゲーム全体の状態を渡します。
/// 戻り値: 反対側のプレイヤーを返します。
pub fn opponent_player(model: Model) -> Player {
  player_by_turn(model, other_turn(model.turn))
}

/// 概要: 指定した手番に対応するプレイヤーを返します。
/// 引数: `model` にゲーム全体の状態を渡します。
/// 引数: `turn` に取得したい手番を渡します。
/// 戻り値: 指定した手番のプレイヤーを返します。
pub fn player_by_turn(model: Model, turn: Turn) -> Player {
  case turn {
    PlayerOne -> model.player_one
    PlayerTwo -> model.player_two
  }
}

/// 概要: 現在の手番プレイヤーを差し替えます。
/// 引数: `model` に現在のゲーム状態を渡します。
/// 引数: `player` に新しいプレイヤー情報を渡します。
/// 戻り値: 現在手番のプレイヤーだけを更新した新しい状態を返します。
pub fn set_current_player(model: Model, player: Player) -> Model {
  set_player(model, model.turn, player)
}

/// 概要: 相手プレイヤーを差し替えます。
/// 引数: `model` に現在のゲーム状態を渡します。
/// 引数: `player` に新しいプレイヤー情報を渡します。
/// 戻り値: 相手プレイヤーだけを更新した新しい状態を返します。
pub fn set_opponent_player(model: Model, player: Player) -> Model {
  set_player(model, other_turn(model.turn), player)
}

/// 概要: 指定した手番のプレイヤーを差し替えます。
/// 引数: `model` に現在のゲーム状態を渡します。
/// 引数: `turn` に対象手番を渡します。
/// 引数: `player` に新しい情報を渡します。
/// 戻り値: 指定した手番のプレイヤーを更新した新しい状態を返します。
pub fn set_player(model: Model, turn: Turn, player: Player) -> Model {
  case turn {
    PlayerOne -> Model(..model, player_one: player)
    PlayerTwo -> Model(..model, player_two: player)
  }
}
