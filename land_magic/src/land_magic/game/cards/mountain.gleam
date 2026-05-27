import land_magic/game/rules
import land_magic/model/domain.{land_name, other_turn, turn_name}
import land_magic/model/types.{
  type Model,
  type Land,
  type Turn,
  Player,
  EndTurnReady,
  ChooseMountainTarget,
  Model,
  Picked,
}
import land_magic/state/players.{player_by_turn, set_player}

/// 概要: 山を出したときの効果を解決します。
/// 引数: `model` に現在の状態を渡します。
/// 引数: `card` に山カードを渡します。
/// 戻り値: 戦場の確認や次の操作待ちを反映した新しい状態を返します。
pub fn resolve_on_play(model: Model, card: Land) -> Model {
  let opponent = player_by_turn(model, other_turn(model.turn))

  case opponent.battlefield {
    // 相手の戦場に何もなければ、壊す対象がない。
    [] -> {
      let model = rules.log_action(
        model,
        turn_name(model.turn) <> "が" <> land_name(card) <> "を解決しましたが、相手の戦場にカードがありません。",
      )

      rules.finalize_after_action(Model(..model, prompt: EndTurnReady, prompt_message: turn_name(model.turn) <> "が" <> land_name(card) <> "を解決しましたが、相手の戦場にカードがありません。ターン終了してください。"))
    }

    // 戦場にカードがあるなら、どれを壊すか選ばせる。
    _ ->
      rules.log_and_prompt(
        model,
        turn_name(model.turn) <> "が" <> land_name(card) <> "を解決しました。",
        ChooseMountainTarget(card),
      )
  }
}

/// 概要: 山で破壊する戦場カードを選んだときの処理を行います。
/// 引数: `model` に現在の状態を渡します。
/// 引数: `owner` に対象プレイヤーを渡します。
/// 引数: `index` に戦場内の位置を渡します。
/// 戻り値: 戦場と墓地を更新した新しい状態を返します。
pub fn resolve_target(model: Model, owner: Turn, index: Int) -> Model {
  let target_player = player_by_turn(model, owner)

  // 指定された戦場のカードを取り除く。
  case rules.remove_at(target_player.battlefield, index, 0) {
    #(new_battlefield, Picked(destroyed_card)) -> {
      // 壊したカードは墓地に置く。
      let target_player = Player(
        ..target_player,
        battlefield: new_battlefield,
        graveyard: [destroyed_card, ..target_player.graveyard],
      )
      let model = set_player(model, owner, target_player)
      let model = rules.log_action(
        model,
        turn_name(model.turn)
          <> "が山で"
          <> turn_name(owner)
          <> "の"
          <> land_name(destroyed_card)
          <> "を破壊しました。",
      )

      rules.finalize_after_action(Model(..model, prompt: EndTurnReady))
    }

    _ -> model
  }
}
