import land_magic/game/rules
import land_magic/game/setup
import land_magic/model/domain.{land_name, turn_name}
import land_magic/model/types.{
  type Model,
  type Land,
  Model,
  Picked,
  EndTurnReady,
  ChooseForestDraw,
}
import land_magic/state/players.{current_player, set_current_player}

/// 概要: 森を出したときの効果を解決します。
/// 引数: `model` に現在の状態を渡します。
/// 引数: `card` に森カードを渡します。
/// 戻り値: 山札の確認や次の操作待ちを反映した新しい状態を返します。
pub fn resolve_on_play(model: Model, card: Land) -> Model {
  let current = current_player(model)

  case current.deck {
    // 山札が空なら、引く処理に進めない。
    [] -> {
      let model = rules.log_action(
        model,
        turn_name(model.turn) <> "が" <> land_name(card) <> "を解決しましたが、山札が空です。",
      )

      rules.finalize_after_action(Model(..model, prompt: EndTurnReady, prompt_message: turn_name(model.turn) <> "が" <> land_name(card) <> "を解決しましたが、山札が空です。ターン終了してください。"))
    }

    // 山札があれば、1枚引く画面に進む。
    _ ->
      rules.log_and_prompt(
        model,
        turn_name(model.turn) <> "が" <> land_name(card) <> "を解決しました。",
        ChooseForestDraw(card),
      )
  }
}

/// 概要: 森の効果で山札から1枚引きます。
/// 引数: `model` に現在の状態を渡します。
/// 戻り値: 引けたカードやログを反映した新しい状態を返します。
pub fn resolve_draw(model: Model) -> Model {
  let current = current_player(model)

  case setup.draw_random_card(current) {
    #(updated_current, Picked(drawn_card)) -> {
      // 山札から引いたカードを手札へ加える。
      let model = set_current_player(model, updated_current)
      let model = rules.log_action(
        model,
        turn_name(model.turn) <> "が森で" <> land_name(drawn_card) <> "を引きました。",
      )

      // 引き終わったら、ターン終了待ちにする。
      rules.finalize_after_action(Model(..model, prompt: EndTurnReady))
    }

    // もし引けなかった場合でも、終了待ちのまま進める。
    _ ->
      rules.finalize_after_action(
        rules.log_and_prompt(
          model,
          turn_name(model.turn) <> "は山札が空で引けませんでした。ターン終了してください。",
          EndTurnReady,
        ),
      )
  }
}