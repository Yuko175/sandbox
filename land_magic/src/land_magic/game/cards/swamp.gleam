import land_magic/game/rules
import land_magic/model/domain.{land_name, other_turn, turn_name}
import land_magic/model/types.{
  type Model,
  type Land,
  Player,
  EndTurnReady,
  ChooseSwampTarget,
  Model,
  Picked,
}
import land_magic/state/players.{current_player, set_current_player}

/// 概要: 沼を出したときの効果を解決します。
/// 引数: `model` に現在の状態を渡します。
/// 引数: `card` に沼カードを渡します。
/// 戻り値: 相手の手札確認や次の操作待ちを反映した新しい状態を返します。
pub fn resolve_on_play(model: Model, card: Land) -> Model {
  case current_player(model).hand {
    // 相手の手札が空なら、捨てさせる相手がいない。
    [] -> {
      let model = rules.log_action(
        model,
        turn_name(other_turn(model.turn))
          <> "が"
          <> land_name(card)
          <> "を解決しましたが、相手の手札がありません。",
      )

      rules.finalize_after_action(Model(..model, turn: other_turn(model.turn), prompt: EndTurnReady, prompt_message: turn_name(other_turn(model.turn)) <> "が" <> land_name(card) <> "を解決しましたが、相手の手札がありません。ターン終了してください。"))
    }

    // 相手に手札があるなら、どれを捨てるか選ばせる。
    _ -> {
      let model = rules.log_and_prompt(
        model,
        turn_name(other_turn(model.turn)) <> "が" <> land_name(card) <> "を解決しました。",
        ChooseSwampTarget(card),
      )

      Model(..model, turn: other_turn(model.turn))
    }
  }
}

/// 概要: 沼で相手の手札から捨てるカードを選んだときの処理を行います。
/// 引数: `model` に現在の状態を渡します。
/// 引数: `index` に相手手札の位置を渡します。
/// 戻り値: 相手の手札と墓地を更新した新しい状態を返します。
pub fn resolve_target(model: Model, index: Int) -> Model {
  let opponent = current_player(model)

  // 選んだカードを相手の手札から取り除く。
  case rules.remove_at(opponent.hand, index, 0) {
    #(new_hand, Picked(discarded_card)) -> {
      // 捨てたカードは墓地に移動する。
      let opponent = Player(..opponent, hand: new_hand, graveyard: [discarded_card, ..opponent.graveyard])
      let model = set_current_player(model, opponent)
      let model = rules.log_action(
        model,
        turn_name(model.turn) <> "が沼で" <> land_name(discarded_card) <> "を捨てました。",
      )

      rules.finalize_after_action(Model(..model, turn: other_turn(model.turn), prompt: EndTurnReady))
    }

    _ -> model
  }
}
