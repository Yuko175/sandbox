import gleam/int
import gleam/list
import land_magic/model/types.{
  type Land,
  type Prompt,
  type Msg,
  type Turn,
  CounterWindow,
  CounterSelecting,
  ChoosePlainsTarget,
  ChooseSwampTarget,
  ChooseMountainTarget,
  DrawFromDeck,
}
import land_magic/view/cards
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

/// 概要: 手札エリアを表示します。
/// 引数: `cards` に手札を渡します。
/// 引数: `active` に手番中かを渡します。
/// 引数: `prompt` に現在の操作を渡します。
/// 引数: `playable` にプレイ可能かを渡します。
/// 戻り値: 手札ゾーンの要素を返します。
pub fn hand_zone(cards: List(Land), active: Bool, prompt: Prompt, playable: Bool) -> Element(Msg) {
  let cards_view =
    case prompt {
      CounterWindow(_) ->
        case active {
          True -> cards.render_static_cards(cards)
          False -> cards.render_static_cards(cards)
        }

      ChooseSwampTarget(_) ->
        case active {
          True -> cards.render_discard_hand_cards(cards, 0)
          False -> cards.render_static_cards(cards)
        }

      CounterSelecting(_, selected) ->
        case active {
          True -> cards.render_counter_hand_cards(cards, 0, selected)
          False -> cards.render_static_cards(cards)
        }

      _ ->
        case playable {
          True -> cards.render_play_hand_cards(cards, 0)
          False -> cards.render_static_cards(cards)
        }
    }

  html.div(
    [attribute.classes([#("zone", True), #("hand-zone", True)])],
    [
      html.h3([], [html.text("手札 (" <> int.to_string(list.length(cards)) <> ")")]),
      html.div([attribute.classes([#("card-row", True)])], cards_view),
    ],
  )
}

/// 概要: 山札エリアを表示します。
/// 引数: `cards` に山札を渡します。
/// 引数: `can_draw` に引けるかどうかを渡します。
/// 戻り値: 山札ゾーンの要素を返します。
pub fn deck_zone(cards: List(Land), can_draw: Bool) -> Element(Msg) {
  let count = list.length(cards)

  html.div(
    [attribute.classes([#("zone", True), #("deck-zone", True)])],
    [
      html.h3([], [html.text("山札 (" <> int.to_string(count) <> ")")]),
      html.button(
        [
          attribute.classes([#("deck-button", True)]),
          attribute.disabled(count == 0 || !can_draw),
          event.on_click(DrawFromDeck),
        ],
        [
          html.span([attribute.classes([#("deck-button-label", True)])], [html.text("山札")]),
          html.strong([], [html.text(int.to_string(count) <> " 枚")]),
        ],
      ),
    ],
  )
}

/// 概要: 任意のゾーンを共通レイアウトで表示します。
/// 引数: `label` に見出しを渡します。
/// 引数: `cards` にカード一覧を渡します。
/// 引数: `zone_class` に CSS クラス名を渡します。
/// 戻り値: 共通レイアウトのゾーン要素を返します。
pub fn zone_view(label: String, cards: List(Land), zone_class: String) -> Element(Msg) {
  html.div(
    [attribute.classes([#("zone", True), #(zone_class, True)])],
    [
      html.h3([], [html.text(label <> " (" <> int.to_string(list.length(cards)) <> ")")]),
      html.div([attribute.classes([#("card-row", True)])], cards.render_static_cards(cards)),
    ],
  )
}

/// 概要: 墓地エリアを表示します。
/// 引数: `cards` に墓地のカードを渡します。
/// 引数: `active` に手番中かを渡します。
/// 引数: `prompt` に現在の操作を渡します。
/// 戻り値: 墓地ゾーンの要素を返します。
pub fn graveyard_zone(cards: List(Land), active: Bool, prompt: Prompt) -> Element(Msg) {
  let plains_active =
    case prompt {
      ChoosePlainsTarget(_) if active -> True
      _ -> False
    }

  let cards_view = cards.render_graveyard_buttons(cards, plains_active)

  html.div(
    [attribute.classes([#("zone", True), #("graveyard-zone", True)])],
    [
      html.h3([], [html.text("墓地 (" <> int.to_string(list.length(cards)) <> ")")]),
      html.div([attribute.classes([#("card-row", True)])], cards_view),
    ],
  )
}

/// 概要: 戦場エリアを表示します。
/// 引数: `cards` に戦場のカードを渡します。
/// 引数: `prompt` に現在の操作を渡します。
/// 引数: `is_active` に自分の戦場かを渡します。
/// 引数: `owner` に対象の手番を渡します。
/// 戻り値: 戦場ゾーンの要素を返します。
pub fn battlefield_zone(cards: List(Land), prompt: Prompt, is_active: Bool, owner: Turn) -> Element(Msg) {
  let elements = cards.render_static_cards(cards)

  let elements_view =
    case prompt {
      CounterWindow(_) if !is_active ->
        case elements {
          [] -> [cards.facedown_chip()]
          [_first, ..rest] -> [cards.facedown_chip(), ..rest]
        }

      CounterSelecting(_, _) if !is_active ->
        case elements {
          [] -> [cards.facedown_chip()]
          [_first, ..rest] -> [cards.facedown_chip(), ..rest]
        }

      ChooseMountainTarget(_) if !is_active -> cards.render_destroy_battlefield_cards(cards, 0, owner)

      _ -> elements
    }

  let total_count = list.length(cards)

  html.div(
    [attribute.classes([#("zone", True), #("battlefield-zone", True)])],
    [
      html.h3([], [html.text("戦場 (" <> int.to_string(total_count) <> ")")]),
      html.div([attribute.classes([#("card-row", True)])], elements_view),
    ],
  )
}
