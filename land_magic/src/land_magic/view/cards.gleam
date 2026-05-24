import gleam/int
import land_magic/model/domain.{land_class, land_name}
import land_magic/model/types.{type Land, type Msg, PlayCard, SelectCounterCard, ReturnFromGraveyard, DiscardOpponentCard, DestroyFromBattlefield, type Turn, Plains, Island, Swamp, Mountain, Forest}
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
      hand_card_button(card, PlayCard(index), False),
      ..render_play_hand_cards(rest, index + 1)
    ]
  }
}

pub fn render_counter_hand_cards(cards: List(Land), index: Int, selected: List(Int)) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] -> [
      hand_card_button(card, SelectCounterCard(index), index_in(selected, index)),
      ..render_counter_hand_cards(rest, index + 1, selected)
    ]
  }
}

pub fn render_return_hand_cards(cards: List(Land), index: Int) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] -> [
      hand_card_button(card, ReturnFromGraveyard(index), False),
      ..render_return_hand_cards(rest, index + 1)
    ]
  }
}

pub fn render_discard_hand_cards(cards: List(Land), index: Int) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] -> [
      hand_card_button(card, DiscardOpponentCard(index), False),
      ..render_discard_hand_cards(rest, index + 1)
    ]
  }
}

pub fn render_destroy_battlefield_cards(cards: List(Land), index: Int, owner: Turn) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] -> [
      hand_card_button(card, DestroyFromBattlefield(owner, index), False),
      ..render_destroy_battlefield_cards(rest, index + 1, owner)
    ]
  }
}

pub fn render_graveyard_buttons(cards: List(Land)) -> List(Element(Msg)) {
  graveyard_buttons(cards, [Plains, Island, Swamp, Mountain, Forest])
}

pub fn land_chip(land: Land) -> Element(Msg) {
  html.span(
    [attribute.classes([#("card-chip", True), #(land_class(land), True)]), attribute.title(land_name(land))],
    [
      html.img([attribute.classes([#("card-image", True)]), attribute.src(image_src(land)), attribute.alt(land_name(land))]),
      html.span([attribute.classes([#("card-label", True)])], [html.text(land_name(land))]),
    ],
  )
}

pub fn facedown_chip() -> Element(Msg) {
  html.span(
    [attribute.classes([#("card-chip", True), #("facedown", True)]), attribute.title("伏せカード")],
    [
      html.img([attribute.classes([#("card-image", True)]), attribute.src(back_image_src()), attribute.alt("伏せカード")]),
      html.span([attribute.classes([#("card-label", True)])], [html.text("？")]),
    ],
  )
}

pub fn hand_card_button(land: Land, message: Msg, selected: Bool) -> Element(Msg) {
  let selected_class = case selected {
    True -> #( "selected", True )
    False -> #( "selected", False )
  }

  let classes = [#("card-chip", True), #("card-chip-button", True), #(land_class(land), True), #("with-image", True), selected_class]

  html.button(
    [
      attribute.classes(classes),
      attribute.title(land_name(land)),
      event.on_click(message),
    ],
    [
      html.img([attribute.classes([#("card-image", True)]), attribute.src(image_src(land)), attribute.alt(land_name(land))]),
      html.span([attribute.classes([#("card-label", True)])], [html.text(land_name(land))]),
    ],
  )
}

fn graveyard_buttons(cards: List(Land), targets: List(Land)) -> List(Element(Msg)) {
  case targets {
    [] -> []
    [target, ..rest] ->
      case render_graveyard_button(cards, target, 0) {
        [] -> graveyard_buttons(cards, rest)
        [button, .._] -> [button, ..graveyard_buttons(cards, rest)]
      }
  }
}

fn render_graveyard_button(cards: List(Land), target: Land, start_index: Int) -> List(Element(Msg)) {
  let count = land_count(cards, target)

  case count > 0 {
    True -> [graveyard_card_button(target, count, ReturnFromGraveyard(first_index_of(cards, target, start_index)))]
    False -> []
  }
}

fn graveyard_card_button(land: Land, count: Int, message: Msg) -> Element(Msg) {
  html.button(
    [
      attribute.classes([
        #("card-chip", True),
        #("card-chip-button", True),
        #("with-image", True),
        #("graveyard-card-button", True),
        #(land_class(land), True),
      ]),
      attribute.title(land_name(land)),
      event.on_click(message),
    ],
    [
      html.img([attribute.classes([#("card-image", True)]), attribute.src(image_src(land)), attribute.alt(land_name(land))]),
      html.span([attribute.classes([#("card-label", True)])], [html.text("×" <> int.to_string(count))]),
    ],
  )
}

fn land_count(cards: List(Land), target: Land) -> Int {
  case cards {
    [] -> 0
    [card, ..rest] ->
      case card == target {
        True -> 1 + land_count(rest, target)
        False -> land_count(rest, target)
      }
  }
}

fn first_index_of(cards: List(Land), target: Land, index: Int) -> Int {
  case cards {
    [] -> 0
    [card, ..rest] ->
      case card == target {
        True -> index
        False -> first_index_of(rest, target, index + 1)
      }
  }
}

fn image_src(land: Land) -> String {
  case land_class(land) {
    "plains" -> "images/plain.jpg"
    "island" -> "images/island.jpg"
    "swamp" -> "images/swamp.jpg"
    "mountain" -> "images/mountain.jpg"
    "forest" -> "images/forest.jpg"
    _ -> back_image_src()
  }
}

fn back_image_src() -> String {
  "images/back.jpg"
}

fn index_in(selected: List(Int), index: Int) -> Bool {
  case selected {
    [] -> False
    [i, ..rest] ->
      case i == index {
        True -> True
        False -> index_in(rest, index)
      }
  }
}
