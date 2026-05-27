import land_magic/game/rules
import land_magic/model/domain.{land_name, turn_name}
import land_magic/model/types.{
  type Model,
  type Land,
  Player,
  EndTurnReady,
  ChoosePlainsTarget,
  Model,
  Picked,
}
import land_magic/state/players.{current_player, set_current_player}

/// 概要: 平地を出したときの効果を解決します。
/// 引数: `model` に現在の状態を渡します。
/// 引数: `card` に平地カードを渡します。
/// 戻り値: 墓地の確認や次の操作待ちを反映した新しい状態を返します。
pub fn resolve_on_play(model: Model, card: Land) -> Model {
  let current = current_player(model)

  case current.graveyard {
    // 墓地にカードがないなら、戻す対象がないので終了待ちにする。
    [] -> {
      let model = rules.log_action(
        model,
        turn_name(model.turn)
          <> "が"
          <> land_name(card)
          <> "を解決しましたが、墓地に対象がありません。",
      )

      rules.finalize_after_action(Model(..model, prompt: EndTurnReady, prompt_message: turn_name(model.turn) <> "が" <> land_name(card) <> "を解決しましたが、墓地に対象がありません。ターン終了してください。"))
    }

    // 墓地にカードがあれば、戻すカードを選ぶ画面へ進む。
    _ ->
      rules.log_and_prompt(
        model,
        turn_name(model.turn) <> "が" <> land_name(card) <> "を解決しました。",
        ChoosePlainsTarget(card),
      )
  }
}

/// 概要: 平地で墓地から戻すカードを選んだときの処理を行います。
/// 引数: `model` に現在の状態を渡します。
/// 引数: `index` に墓地内の位置を渡します。
/// 戻り値: 手札と墓地を更新した新しい状態を返します。
pub fn resolve_target(model: Model, index: Int) -> Model {
  let current = current_player(model)

  // 指定された位置のカードを墓地から取り出す。
  case rules.remove_at(current.graveyard, index, 0) {
    #(new_graveyard, Picked(returned_card)) -> {
      // 取り出したカードを手札に加え、墓地は減らす。
      let current = Player(..current, graveyard: new_graveyard, hand: [returned_card, ..current.hand])
      let model = set_current_player(model, current)
      let model = rules.log_action(
        model,
        turn_name(model.turn) <> "が平地で" <> land_name(returned_card) <> "を回収しました。",
      )

      rules.finalize_after_action(Model(..model, prompt: EndTurnReady))
    }

    _ -> model
  }
}
