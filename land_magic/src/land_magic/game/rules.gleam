import gleam/list
import land_magic/model/types.{
  type Land,
  type Model,
  Model,
  type Prompt,
  type Winner,
  Plains,
  Island,
  Swamp,
  Mountain,
  Forest,
  PlayerOne,
  PlayerTwo,
  NoWinner,
  HasWinner,
  GameOver,
  NotPicked,
  Picked,
  type PickResult,
}

/// 概要: 行動後に勝利条件を確認し、必要ならゲーム終了状態にします。
/// 引数: `model` に最新のゲーム状態を渡します。
/// 戻り値: 勝者がいればゲーム終了、いなければそのままの状態を返します。
pub fn finalize_after_action(model: Model) -> Model {
  case winner(model) {
    HasWinner(turn) -> Model(..model, prompt: GameOver(turn))
    NoWinner -> model
  }
}

/// 概要: ログを1件追加し、次の画面表示を設定します。
/// 引数: `model` に現在の状態を渡します。
/// 引数: `entry` に追加するログを渡します。
/// 引数: `prompt` に次の操作内容を渡します。
/// 戻り値: ログと表示状態を更新した新しい状態を返します。
pub fn log_and_prompt(model: Model, entry: String, prompt: Prompt) -> Model {
  let model = log_action(model, entry)
  Model(..model, prompt: prompt)
}

/// 概要: アクションログを1件追加します。
/// 引数: `model` に現在の状態を渡します。
/// 引数: `entry` に追加するログ文を渡します。
/// 戻り値: ログだけを更新した新しい状態を返します。
pub fn log_action(model: Model, entry: String) -> Model {
  Model(..model, log: [entry, ..model.log])
}

/// 概要: 勝者がいるかどうかを判定します。
/// 引数: `model` に現在のゲーム状態を渡します。
/// 戻り値: 勝者がいれば `HasWinner`、いなければ `NoWinner` を返します。
pub fn winner(model: Model) -> Winner {
  case has_all_five(model.player_one.battlefield) {
    True -> HasWinner(PlayerOne)
    False ->
      case has_all_five(model.player_two.battlefield) {
        True -> HasWinner(PlayerTwo)
        False -> NoWinner
      }
  }
}

/// 概要: 5種類すべての土地がそろっているかを調べます。
/// 引数: `cards` に戦場のカード一覧を渡します。
/// 戻り値: 5種類がそろっていれば `True`、そうでなければ `False` を返します。
pub fn has_all_five(cards: List(Land)) -> Bool {
  contains_land(cards, Plains)
    && contains_land(cards, Island)
    && contains_land(cards, Swamp)
    && contains_land(cards, Mountain)
    && contains_land(cards, Forest)
}

/// 概要: どちらかの戦場にカードがあるかを調べます。
/// 引数: `model` に現在のゲーム状態を渡します。
/// 戻り値: 戦場に1枚でもあれば `True` を返します。
pub fn battlefield_exists(model: Model) -> Bool {
  list.length(model.player_one.battlefield) + list.length(model.player_two.battlefield) > 0
}

/// 概要: 打ち消しに必要な手札があるかを調べます。
/// 引数: `cards` に手札の一覧を渡します。
/// 戻り値: 島を含み、さらに別の1枚か島2枚以上があれば `True` を返します。
pub fn has_counter_cost(cards: List(Land)) -> Bool {
  let island_count = count_island(cards)
  case island_count > 1 {
    True -> True
    // 島が1枚だけなら、島以外のカードがもう1枚必要。
    False -> island_count > 0 && count_non_island(cards) > 0
  }
}

/// 概要: 手札にある島の枚数を数えます。
/// 引数: `cards` に土地カードの一覧を渡します。
/// 戻り値: 島の枚数を整数で返します。
pub fn count_island(cards: List(Land)) -> Int {
  case cards {
    [] -> 0
    [card, ..rest] ->
      case card == Island {
        True -> 1 + count_island(rest)
        // 島ではないカードは数えずに次へ進む。
        False -> count_island(rest)
      }
  }
}

/// 概要: 島以外のカード枚数を数えます。
/// 引数: `cards` に土地カードの一覧を渡します。
/// 戻り値: 島以外の枚数を整数で返します。
pub fn count_non_island(cards: List(Land)) -> Int {
  case cards {
    [] -> 0
    [card, ..rest] ->
      case card == Island {
        // 島は数えない。
        True -> count_non_island(rest)
        // 島以外なら 1 枚として数える。
        False -> 1 + count_non_island(rest)
      }
  }
}

/// 概要: 指定した種類のカードがあるかを調べます。
/// 引数: `cards` にカード一覧を渡します。
/// 引数: `target` に探したい土地カードを渡します。
/// 戻り値: 見つかれば `True`、なければ `False` を返します。
pub fn contains_land(cards: List(Land), target: Land) -> Bool {
  case cards {
    [] -> False
    [card, ..rest] ->
      case card == target {
        // 見つかったらそこで終了する。
        True -> True
        False -> contains_land(rest, target)
      }
  }
}

/// 概要: 指定した位置のカードを取り除きます。
/// 引数: `cards` にカード一覧を渡します。
/// 引数: `target_index` に消したい位置を渡します。
/// 引数: `current_index` に再帰用の現在位置を渡します。
/// 戻り値: 取り除いた後の一覧と、取り除けたカードを返します。
pub fn remove_at(cards: List(Land), target_index: Int, current_index: Int) -> #(List(Land), PickResult(Land)) {
  case cards {
    [] -> #([], NotPicked)
    [card, ..rest] ->
      case current_index == target_index {
        // 目的の位置に来たら、そのカードを取り除く。
        True -> #(rest, Picked(card))
        False -> {
          // 先頭ではなければ、残りを再帰的に探す。
          let #(new_rest, pick) = remove_at(rest, target_index, current_index + 1)
          #([card, ..new_rest], pick)
        }
      }
  }
}
