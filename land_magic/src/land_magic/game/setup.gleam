import gleam/int
import gleam/list
import land_magic/game/rules
import land_magic/model/domain.{land_name, turn_name}
import land_magic/model/types.{
  type Land,
  type Turn,
  type Player,
  type Model,
  type PickResult,
  Plains,
  Island,
  Swamp,
  Mountain,
  Forest,
  PlayerOne,
  PlayerTwo,
  Player,
  Picked,
  NotPicked,
}
import land_magic/state/players.{current_player, set_current_player}

/// 概要: 山札から1枚をランダムに引きます。
/// 引数: `player` に対象プレイヤーを渡します。
/// 戻り値: 山札と手札を更新したプレイヤー、および引けたカード情報を返します。
pub fn draw_random_card(player: Player) -> #(Player, PickResult(Land)) {
  case player.deck {
    [] -> #(player, NotPicked)

    deck -> {
      // 山札の枚数の中からランダムな位置を決める。
      let index = int.random(list.length(deck))
      case rules.remove_at(deck, index, 0) {
        // 引いたカードを山札から抜き、手札に入れる。
        #(new_deck, Picked(card)) -> #(Player(..player, deck: new_deck, hand: [card, ..player.hand]), Picked(card))
        _ -> #(player, NotPicked)
      }
    }
  }
}

/// 概要: ゲーム開始時の初期手札を作ります。
/// 引数: `player` に対象プレイヤーを渡します。
/// 引数: `count` に引く枚数を渡します。
/// 戻り値: 指定枚数だけ手札を配ったプレイヤーを返します。
pub fn draw_opening_hand(player: Player, count: Int) -> Player {
  case count {
    0 -> player
    _ ->
      case player.deck {
        [] -> player
        [card, ..rest] -> {
          // 山札の先頭を1枚ずつ手札へ移していく。
          let player = Player(..player, deck: rest, hand: [card, ..player.hand])
          draw_opening_hand(player, count - 1)
        }
      }
  }
}

/// 概要: 新しいプレイヤーを作成します。
/// 引数: `turn` にどちらのプレイヤーかを渡します。
/// 戻り値: デッキと手札が空の新しいプレイヤーを返します。
pub fn new_player(turn: Turn) -> Player {
  case turn {
    PlayerOne ->
      // プレイヤー1はこの土地の並びを基準にデッキを作る。
      Player(
        name: "プレイヤー1",
        deck: repeated_deck([Plains, Island, Swamp, Mountain, Forest], 5, []),
        hand: [],
        battlefield: [],
        graveyard: [],
      )

    PlayerTwo ->
      // プレイヤー2は別の並びでデッキを作る。
      Player(
        name: "プレイヤー2",
        deck: repeated_deck([Forest, Mountain, Swamp, Island, Plains], 5, []),
        hand: [],
        battlefield: [],
        graveyard: [],
      )
  }
}

/// 概要: ターン開始時に自分の山札から1枚引きます。
/// 引数: `model` に現在のゲーム状態を渡します。
/// 戻り値: 引けた場合は手札とログを更新した状態、引けない場合はその旨のログを持つ状態を返します。
pub fn draw_turn_card(model: Model) -> Model {
  let current = current_player(model)

  case current.deck {
    [] ->
      // 山札が空なら、引けなかったことを記録する。
      rules.log_action(
        model,
        turn_name(model.turn) <> "は山札が空のため、ターン開始時に引けませんでした。",
      )

    [drawn_card, ..rest] -> {
      // 山札の先頭1枚を手札に加える。
      let current = Player(..current, deck: rest, hand: [drawn_card, ..current.hand])
      let model = set_current_player(model, current)
      // 何を引いたかをログに残す。
      rules.log_action(
        model,
        turn_name(model.turn) <> "がターン開始時に" <> land_name(drawn_card) <> "を引きました。",
      )
    }
  }
}

/// 概要: 同じカード配列を複数回つないで山札の元を作ります。
/// 引数: `cycle` に繰り返す並びを渡します。
/// 引数: `times` に回数を渡します。
/// 引数: `acc` に蓄積中のカードを渡します。
/// 戻り値: 連結したカード一覧を返します。
fn repeated_deck(cycle: List(Land), times: Int, acc: List(Land)) -> List(Land) {
  // Build the full deck by repeating `cycle` `times` times, then shuffle it.
  let deck = build_deck(cycle, times, acc)
  shuffle(deck, [])
}

/// 概要: 山札の下地を再帰で組み立てます。
/// 引数: `cycle` に基本並びを渡します。
/// 引数: `times` に残り回数を渡します。
/// 引数: `acc` に組み立て済みカードを渡します。
/// 戻り値: 山札の下地となるカード一覧を返します。
fn build_deck(cycle: List(Land), times: Int, acc: List(Land)) -> List(Land) {
  case times {
    0 -> acc
    // 回数が残っている間は、同じ並びを積み上げる。
    _ -> build_deck(cycle, times - 1, append_list(cycle, acc))
  }
}

/// 概要: リストを後ろにつなげます。
/// 引数: `items` に追加したい一覧を渡します。
/// 引数: `acc` に元の一覧を渡します。
/// 戻り値: 2つをつないだ一覧を返します。
fn append_list(items: List(Land), acc: List(Land)) -> List(Land) {
  case items {
    [] -> acc
    // 先頭から順に acc の前に入れていく。
    [card, ..rest] -> [card, ..append_list(rest, acc)]
  }
}

/// 概要: カード一覧をランダムに並べ替えます。
/// 引数: `items` に元の一覧を渡します。
/// 引数: `acc` に並べ替え中の一覧を渡します。
/// 戻り値: シャッフル済みの一覧を返します。
fn shuffle(items: List(Land), acc: List(Land)) -> List(Land) {
  case items {
    [] -> acc
    _ -> {
      // 残っているカードの中から1枚をランダムに抜く。
      let len = list.length(items)
      let index = int.random(len)
      case rules.remove_at(items, index, 0) {
        // 取り出したカードを先頭に積んで、残りを続けてシャッフルする。
        #(rest, Picked(card)) -> shuffle(rest, [card, ..acc])
        _ -> shuffle(items, acc)
      }
    }
  }
}
