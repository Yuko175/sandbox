import land_magic/model/domain.{land_class, land_name}
import land_magic/model/types.{type Land, type Msg, PlayCard, SelectCounterCard}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn render_static_cards(cards: List(Land)) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] -> [land_chip(card), ..render_static_cards(rest)]
  }
}

pub fn render_play_hand_cards(cards: List(Land), index: Int) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] -> [
      hand_card_button(card, PlayCard(index)),
      ..render_play_hand_cards(rest, index + 1)
    ]
  }
}

pub fn render_counter_hand_cards(cards: List(Land), index: Int) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] -> [
      hand_card_button(card, SelectCounterCard(index)),
      ..render_counter_hand_cards(rest, index + 1)
    ]
  }
}

pub fn land_chip(land: Land) -> Element(Msg) {
  html.span(
    [attribute.classes([#("card-chip", True), #(land_class(land), True)]), attribute.title(land_name(land))],
    [html.text(land_name(land))],
  )
}

pub fn hand_card_button(land: Land, message: Msg) -> Element(Msg) {
  html.button(
    [
      attribute.classes([
        #("card-chip", True),
        #("card-chip-button", True),
        #(land_class(land), True),
      ]),
      attribute.title(land_name(land)),
      event.on_click(message),
    ],
    [html.text(land_name(land))],
  )
}
