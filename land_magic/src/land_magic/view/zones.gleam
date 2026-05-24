import gleam/int
import gleam/list
import land_magic/model/types.{
  type Land,
  type Prompt,
  type Msg,
  CounterWindow,
  CounterSelecting,
  BeginCounterSelection,
  PassCounter,
  DrawFromDeck,
}
import land_magic/view/cards
import land_magic/view/common
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn hand_zone(cards: List(Land), active: Bool, prompt: Prompt, playable: Bool) -> Element(Msg) {
  let cards_view =
    case prompt {
      CounterWindow(_) ->
        case active {
          True -> cards.render_static_cards(cards)
          False -> cards.render_static_cards(cards)
        }

      CounterSelecting(_, _) ->
        case active {
          True -> cards.render_counter_hand_cards(cards, 0)
          False -> cards.render_static_cards(cards)
        }

      _ ->
        case playable {
          True -> cards.render_play_hand_cards(cards, 0)
          False -> cards.render_static_cards(cards)
        }
    }

  let counter_enabled =
    case prompt {
      CounterWindow(_) -> True
      CounterSelecting(_, _) -> True
      _ -> False
    }

  let counter_select_enabled =
    case prompt {
      CounterSelecting(_, _) -> True
      _ -> False
    }

  let footer = [
    html.div([attribute.classes([#("action-grid", True)])], [
      common.button_control("secondary", "打ち消し", BeginCounterSelection, active && counter_enabled),
      common.button_control("secondary", "打ち消しパス", PassCounter, active && counter_enabled),
    ]),
  ]

  html.div(
    [attribute.classes([#("zone", True), #("hand-zone", True)])],
    [
      html.h3([], [html.text("手札 (" <> int.to_string(list.length(cards)) <> ")")]),
      html.div([attribute.classes([#("card-row", True)])], cards_view),
      case active && counter_select_enabled {
        True -> html.p([], [html.text("島を含む2枚を選んでください。")])
        False -> html.text("")
      },
      ..footer,
    ],
  )
}

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

pub fn zone_view(label: String, cards: List(Land), zone_class: String) -> Element(Msg) {
  html.div(
    [attribute.classes([#("zone", True), #(zone_class, True)])],
    [
      html.h3([], [html.text(label <> " (" <> int.to_string(list.length(cards)) <> ")")]),
      html.div([attribute.classes([#("card-row", True)])], cards.render_static_cards(cards)),
    ],
  )
}
