import land_magic/game/rules
import land_magic/model/domain.{land_name, other_turn, turn_name}
import land_magic/model/types.{
  type Model,
  type Land,
  Model,
  Player,
  EndTurnReady,
  CounterSelecting,
  Picked,
  Island,
}
import land_magic/state/players.{current_player, opponent_player, set_current_player, set_opponent_player}

/// 概要: 打ち消しに使うカード選択を始めます。
/// 引数: `model` に現在の状態を渡します。
/// 引数: `card` に対象のカードを渡します。
/// 戻り値: 打ち消しの選択画面に切り替えた状態を返します。
pub fn begin_counter_selection(model: Model, card: Land) -> Model {
  Model(..model, prompt: CounterSelecting(card, []))
}

/// 概要: 打ち消しに使う手札カードを選びます。
/// 引数: `model` に現在の状態を渡します。
/// 引数: `card` に対象のカードを渡します。
/// 引数: `index` に選んだ位置を渡します。
/// 戻り値: 選択中の状態を更新した新しい状態を返します。
pub fn select_counter_card(model: Model, card: Land, index: Int) -> Model {
  case model.prompt {
    CounterSelecting(_, selected) ->
      case selected {
        // まだ1枚も選んでいないなら、最初の1枚として覚える。
        [] -> Model(..model, prompt: CounterSelecting(card, [index]))

        [first_index, ..] ->
          case first_index == index {
            // 同じカードを2回押しただけなら、何もしない。
            True -> model
            // 2枚そろったので、打ち消しの成立判定へ進む。
            False -> resolve_counter_selection(model, card, first_index, index)
          }
      }

    _ -> model
  }
}

/// 概要: 打ち消しをパスします。
/// 引数: `model` に現在の状態を渡します。
/// 引数: `_card` に対象カードを渡します。
/// 戻り値: 打ち消しをパスした記録を持つ状態を返します。
pub fn pass_counter(model: Model, _card: Land) -> Model {
  let model = rules.log_action(model, turn_name(model.turn) <> "は打ち消しをパスしました。")
  Model(..model, turn: other_turn(model.turn))
}

/// 概要: 島を出したときの効果を解決します。
/// 引数: `model` に現在の状態を渡します。
/// 引数: `card` に島カードを渡します。
/// 戻り値: 打ち消し待ちのない解決結果を返します。
pub fn resolve_on_play(model: Model, card: Land) -> Model {
  rules.finalize_after_action(
    rules.log_and_prompt(
      model,
      turn_name(model.turn) <> "が" <> land_name(card) <> "を解決しました。",
      EndTurnReady,
    ),
  )
}

/// 概要: 打ち消しに使う2枚を確定して処理します。
/// 引数: `model` に現在の状態を渡します。
/// 引数: `card` に打ち消すカードを渡します。
/// 引数: `first_index` に 1 つ目の選択位置を渡します。
/// 引数: `second_index` に 2 つ目の選択位置を渡します。
/// 戻り値: 打ち消し成立または再選択の新しい状態を返します。
fn resolve_counter_selection(model: Model, card: Land, first_index: Int, second_index: Int) -> Model {
  let defender = current_player(model)
  // 2枚の選択順が逆でも同じになるように、先に小さい index を決める。
  let low_index = case first_index < second_index {
    True -> first_index
    False -> second_index
  }
  let high_index = case first_index < second_index {
    True -> second_index
    False -> first_index
  }

  let attacker = opponent_player(model)

  // 選ばれた1枚目を手札から取り除く。
  case rules.remove_at(defender.hand, high_index, 0) {
    #(hand_after_high, Picked(high_card)) ->
      // 2枚目も取り除く。
      case rules.remove_at(hand_after_high, low_index, 0) {
        #(final_hand, Picked(low_card)) ->
          // 島を含む2枚でないと打ち消せない。
          case high_card == Island || low_card == Island {
            True -> {
              // 打ち消しに使った2枚を墓地へ送る。
              let defender = Player(
                ..defender,
                hand: final_hand,
                graveyard: [low_card, high_card, ..defender.graveyard],
              )

              // 出されたカードは相手の戦場から取り除いて墓地へ送る。
              let attacker_battle = case attacker.battlefield {
                [] -> []
                [_first, ..rest] -> rest
              }

              let attacker = Player(..attacker, battlefield: attacker_battle, graveyard: [card, ..attacker.graveyard])

              let model = set_current_player(model, defender)
              let model = set_opponent_player(model, attacker)

              // ログでは、島以外の1枚だけを名前で表示する。
              let other_card = case high_card == Island {
                True -> low_card
                False -> high_card
              }

              let model = rules.log_action(
                model,
                turn_name(model.turn)
                  <> "が島と"
                  <> land_name(other_card)
                  <> "を捨て、"
                  <> land_name(card)
                  <> "を打ち消しました。",
              )

              finish_counter(Model(..model, turn: other_turn(model.turn)))
            }

            False ->
              // 島がないので、選び直しを促す。
              rules.log_action(
                Model(..model, prompt: CounterSelecting(card, [])),
                "打ち消しには島と別の1枚を選んでください。",
              )
          }

        _ -> Model(..model, prompt: CounterSelecting(card, []))
      }

    _ -> Model(..model, prompt: CounterSelecting(card, []))
  }
}

/// 概要: 打ち消し処理の終了後に状態を整えます。
/// 引数: `model` に現在の状態を渡します。
/// 戻り値: ターン終了待ち、またはゲーム終了にした状態を返します。
fn finish_counter(model: Model) -> Model {
  // 打ち消しが終わった後も、すぐにはターンを渡さず終了待ちにする。
  rules.finalize_after_action(Model(..model, prompt: EndTurnReady))
}
