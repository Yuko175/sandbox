import gleam/int
import gleam/list
import land_magic/types.{
  type Land,
  type Turn,
  type Player,
  type Prompt,
  type Model,
  type PickResult,
  type Winner,
  type Msg,
  Plains,
  Island,
  Swamp,
  Mountain,
  Forest,
  PlayerOne,
  PlayerTwo,
  Player,
  Model,
  ChoosePlay,
  CounterWindow,
  ChoosePlainsTarget,
  ChooseSwampTarget,
  ChooseMountainTarget,
  ChooseForestDraw,
  EndTurnReady,
  GameOver,
  ResetGame,
  PlayCard,
  CounterWithIsland,
  PassCounter,
  ReturnFromGraveyard,
  DiscardOpponentCard,
  DestroyFromBattlefield,
  DrawForForest,
  FinishTurn,
  Picked,
  NotPicked,
  NoWinner,
  HasWinner,
}
import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn main() -> Nil {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}


fn init(_args: Nil) -> Model {
  let player_one = draw_opening_hand(new_player(PlayerOne), 5)
  let player_two = draw_opening_hand(new_player(PlayerTwo), 5)

  let model = Model(
    player_one: player_one,
    player_two: player_two,
    turn: PlayerOne,
    prompt: ChoosePlay,
    log: [
      "新しいゲームを開始しました。",
      "手札は公開され、すべての選択は手動です。",
    ],
    turn_number: 1,
  )

  begin_turn(model)
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    ResetGame -> init(Nil)

    PlayCard(index) ->
      case model.prompt {
        ChoosePlay -> play_card(model, index)
        _ -> model
      }

    CounterWithIsland(index) ->
      case model.prompt {
        CounterWindow(card) -> counter_with_island(model, card, index)
        _ -> model
      }

    PassCounter ->
      case model.prompt {
        CounterWindow(card) -> resolve_play(model, card)
        _ -> model
      }

    ReturnFromGraveyard(index) ->
      case model.prompt {
        ChoosePlainsTarget(card) -> resolve_plains(model, card, index)
        _ -> model
      }

    DiscardOpponentCard(index) ->
      case model.prompt {
        ChooseSwampTarget(card) -> resolve_swamp(model, card, index)
        _ -> model
      }

    DestroyFromBattlefield(owner, index) ->
      case model.prompt {
        ChooseMountainTarget(card) -> resolve_mountain(model, card, owner, index)
        _ -> model
      }

    DrawForForest ->
      case model.prompt {
        ChooseForestDraw(card) -> resolve_forest(model, card)
        _ -> model
      }

    FinishTurn ->
      case model.prompt {
        ChoosePlay -> end_turn(model)
        ChooseMountainTarget(_) -> end_turn(model)
        EndTurnReady -> end_turn(model)
        _ -> model
      }
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div(
    [attribute.classes([#("app-shell", True)])],
    [
      html.header(
        [attribute.classes([#("hero", True)])],
        [
          html.div([attribute.classes([#("hero-copy", True)])], [
            html.p(
              [attribute.classes([#("eyebrow", True)])],
              [html.text("ランドマジック")],
            ),
            html.h1([], [html.text("手札公開・手動進行・五色の土地で勝利")]),
            html.p(
              [attribute.classes([#("hero-text", True)])],
              [
                html.text(
                  "Lustre SPAで再現したカジュアルなランドマジック。基本土地のみ、手札公開、すべて手動操作。",
                ),
              ],
            ),
          ]),
          html.div(
            [attribute.classes([#("hero-stats", True)])],
            [
              stat_card("ターン", int.to_string(model.turn_number)),
              stat_card("手番", turn_name(model.turn)),
              stat_card("状態", prompt_name(model.prompt)),
            ],
          ),
        ],
      ),
      html.section(
        [attribute.classes([#("panel", True), #(prompt_panel_class(model.prompt), True)])],
        [
          html.div([attribute.classes([#("panel-head", True)])], [
            html.h2([], [html.text(prompt_title(model.prompt, model.turn))]),
            html.p([], [html.text(prompt_body(model))]),
          ]),
          prompt_controls(model),
        ],
      ),
      html.div(
        [attribute.classes([#("board", True)])],
        [
          player_panel(model.player_one, model.turn == PlayerOne),
          player_panel(model.player_two, model.turn == PlayerTwo),
        ],
      ),
      html.section(
        [attribute.classes([#("panel", True), #("log-panel", True)])],
        [
          html.div([attribute.classes([#("panel-head", True)])], [
            html.h2([], [html.text("アクションログ")]),
            html.p([], [html.text("最新の行動が上に表示されます。")]),
          ]),
          html.div([attribute.classes([#("log-list", True)])], render_log_items(model.log, 10)),
        ],
      ),
    ],
  )
}

fn prompt_controls(model: Model) -> Element(Msg) {
  case model.prompt {
    ChoosePlay ->
      html.div([attribute.classes([#("prompt-stack", True)])], [
        html.div(
          [attribute.classes([#("action-grid", True)])],
          render_play_buttons(current_player(model).hand, 0),
        ),
        plain_button("secondary", "ターンを渡す", FinishTurn),
      ])

    CounterWindow(card) ->
      html.div([attribute.classes([#("prompt-stack", True)])], [
        html.p([], [
          html.text(
            "相手は島と他の1枚を捨てて、"
              <> land_name(card)
              <> "を打ち消せます。",
          ),
        ]),
        html.div(
          [attribute.classes([#("action-grid", True)])],
          render_counter_buttons(opponent_player(model).hand, 0),
        ),
        plain_button("secondary", "そのまま解決する", PassCounter),
      ])

    ChoosePlainsTarget(card) ->
      html.div([attribute.classes([#("prompt-stack", True)])], [
        html.p([], [
          html.text("平地は" <> turn_name(model.turn) <> "の墓地からカードを1枚戻します。"),
        ]),
        html.div(
          [attribute.classes([#("action-grid", True)])],
          render_graveyard_buttons(current_player(model).graveyard, 0),
        ),
        html.p([], [html.text(land_name(card) <> "を解決中。")]),
      ])

    ChooseSwampTarget(card) ->
      html.div([attribute.classes([#("prompt-stack", True)])], [
        html.p([], [
          html.text("沼は" <> turn_name(other_turn(model.turn)) <> "に手札を1枚捨てさせます。"),
        ]),
        html.div(
          [attribute.classes([#("action-grid", True)])],
          render_discard_buttons(opponent_player(model).hand, 0),
        ),
        html.p([], [html.text(land_name(card) <> "を解決中。")]),
      ])

    ChooseMountainTarget(card) ->
      html.div([attribute.classes([#("prompt-stack", True)])], [
        html.p([], [
          html.text("山はどちらの戦場の土地も破壊できます。対象を選ぶかスキップしてください。"),
        ]),
        html.div([attribute.classes([#("battlefield-choice", True)])], [
          target_zone("プレイヤー1の戦場", PlayerOne, current_player(model).battlefield),
          target_zone("プレイヤー2の戦場", PlayerTwo, opponent_player(model).battlefield),
        ]),
        html.div([attribute.classes([#("action-grid", True)])], [
          plain_button("secondary", "破壊しない", FinishTurn),
        ]),
        html.p([], [html.text(land_name(card) <> "を解決中。")]),
      ])

    ChooseForestDraw(card) ->
      html.div([attribute.classes([#("prompt-stack", True)])], [
        html.p([], [
          html.text("森は" <> turn_name(model.turn) <> "の山札の一番上を引きます。"),
        ]),
        plain_button("primary", "1枚引く", DrawForForest),
        html.p([], [html.text(land_name(card) <> "を解決中。")]),
      ])

    EndTurnReady ->
      html.div([attribute.classes([#("prompt-stack", True)])], [
        html.p([], [html.text("このターンの処理は完了しました。準備ができたら終了してください。")]),
        plain_button("primary", "ターン終了", FinishTurn),
      ])

    GameOver(winner) ->
      html.div([attribute.classes([#("prompt-stack", True)])], [
        html.p([], [
          html.text(turn_name(winner) <> "が5種類の土地を揃えて勝利しました。"),
        ]),
        plain_button("primary", "新しいゲームを開始", ResetGame),
      ])
  }
}

fn prompt_title(prompt: Prompt, turn: Turn) -> String {
  case prompt {
    ChoosePlay -> turn_name(turn) <> "のプレイ"
    CounterWindow(_) -> "打ち消しタイミング"
    ChoosePlainsTarget(_) -> "平地の効果"
    ChooseSwampTarget(_) -> "沼の効果"
    ChooseMountainTarget(_) -> "山の効果"
    ChooseForestDraw(_) -> "森の効果"
    EndTurnReady -> "ターン終了準備"
    GameOver(_) -> "ゲーム終了"
  }
}

fn prompt_body(model: Model) -> String {
  case model.prompt {
    ChoosePlay -> "手札から土地を選ぶか、ターンを渡してください。"
    CounterWindow(_) -> "島で打ち消す場合は、島ともう1枚を捨てます。"
    ChoosePlainsTarget(_) -> "墓地から手札に戻すカードを選んでください。"
    ChooseSwampTarget(_) -> "相手の手札から捨てさせるカードを選んでください。"
    ChooseMountainTarget(_) -> "両方の戦場から破壊する土地を選ぶか、スキップしてください。"
    ChooseForestDraw(_) -> "山札の一番上を手札に加えてください。"
    EndTurnReady -> "効果の処理が完了しました。"
    GameOver(_) -> "ゲームは終了しました。"
  }
}

fn prompt_name(prompt: Prompt) -> String {
  case prompt {
    ChoosePlay -> "プレイ"
    CounterWindow(_) -> "打ち消し"
    ChoosePlainsTarget(_) -> "平地"
    ChooseSwampTarget(_) -> "沼"
    ChooseMountainTarget(_) -> "山"
    ChooseForestDraw(_) -> "森"
    EndTurnReady -> "終了待ち"
    GameOver(winner) -> turn_name(winner) <> "の勝利"
  }
}

fn prompt_panel_class(prompt: Prompt) -> String {
  case prompt {
    ChoosePlay -> "panel-accent play-accent"
    CounterWindow(_) -> "panel-accent counter-accent"
    ChoosePlainsTarget(_) -> "panel-accent plains-accent"
    ChooseSwampTarget(_) -> "panel-accent swamp-accent"
    ChooseMountainTarget(_) -> "panel-accent mountain-accent"
    ChooseForestDraw(_) -> "panel-accent forest-accent"
    EndTurnReady -> "panel-accent end-accent"
    GameOver(_) -> "panel-accent victory-accent"
  }
}

fn player_panel(player: Player, active: Bool) -> Element(Msg) {
  html.section(
    [attribute.classes([#("panel", True), #(player_panel_class(active), True)])],
    [
      html.div([attribute.classes([#("panel-head", True)])], [
        html.div([attribute.classes([#("title-row", True)])], [
          html.h2([], [html.text(player.name)]),
          case active {
            True -> html.span(
              [attribute.classes([#("badge", True), #("badge-active", True)])],
              [html.text("手番中")],
            )
            False -> html.span([attribute.classes([#("badge", True)])], [html.text("待機中")])
          },
        ]),
        html.p([], [html.text(zone_summary(player))]),
      ]),
      zone_view("手札", player.hand, "hand-zone"),
      zone_view("戦場", player.battlefield, "battlefield-zone"),
      zone_view("墓地", player.graveyard, "graveyard-zone"),
    ],
  )
}

fn zone_view(label: String, cards: List(Land), zone_class: String) -> Element(Msg) {
  html.div(
    [attribute.classes([#("zone", True), #(zone_class, True)])],
    [
      html.h3([], [html.text(label <> " (" <> int.to_string(list.length(cards)) <> ")")]),
      html.div([attribute.classes([#("card-row", True)])], render_static_cards(cards)),
    ],
  )
}

fn zone_summary(player: Player) -> String {
  "山札 "
    <> int.to_string(list.length(player.deck))
    <> " • 手札 "
    <> int.to_string(list.length(player.hand))
    <> " • 戦場 "
    <> int.to_string(list.length(player.battlefield))
    <> " • 墓地 "
    <> int.to_string(list.length(player.graveyard))
}

fn render_static_cards(cards: List(Land)) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] -> [land_chip(card), ..render_static_cards(rest)]
  }
}

fn render_play_buttons(cards: List(Land), index: Int) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] -> [land_action_button("play-card", card, land_name(card), PlayCard(index)), ..render_play_buttons(rest, index + 1)]
  }
}

fn render_counter_buttons(cards: List(Land), index: Int) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] ->
      case card == Island {
        True -> render_counter_buttons(rest, index + 1)
        False -> [
          land_action_button("counter-card", card, land_name(card), CounterWithIsland(index)),
          ..render_counter_buttons(rest, index + 1)
        ]
      }
  }
}

fn render_graveyard_buttons(cards: List(Land), index: Int) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] -> [land_action_button("graveyard-card", card, land_name(card), ReturnFromGraveyard(index)), ..render_graveyard_buttons(rest, index + 1)]
  }
}

fn render_discard_buttons(cards: List(Land), index: Int) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] -> [land_action_button("discard-card", card, land_name(card), DiscardOpponentCard(index)), ..render_discard_buttons(rest, index + 1)]
  }
}

fn target_zone(title: String, owner: Turn, cards: List(Land)) -> Element(Msg) {
  html.div(
    [attribute.classes([#("zone", True), #("target-zone", True)])],
    [
      html.h3([], [html.text(title)]),
      html.div([attribute.classes([#("card-row", True)])], render_battlefield_buttons(owner, cards, 0)),
    ],
  )
}

fn render_battlefield_buttons(owner: Turn, cards: List(Land), index: Int) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] -> [
      land_action_button(
        "battlefield-card",
        card,
        turn_name(owner) <> ": " <> land_name(card),
        DestroyFromBattlefield(owner, index),
      ),
      ..render_battlefield_buttons(owner, rest, index + 1)
    ]
  }
}

fn land_chip(land: Land) -> Element(Msg) {
  html.span(
    [attribute.classes([#("card-chip", True), #(land_class(land), True)]), attribute.title(land_name(land))],
    [html.text(land_name(land))],
  )
}

fn land_action_button(kind: String, land: Land, label: String, message: Msg) -> Element(Msg) {
  html.button(
    [
      attribute.classes([
        #("action-button", True),
        #(kind, True),
        #(land_class(land), True),
      ]),
      event.on_click(message),
    ],
    [html.text(label)],
  )
}

fn plain_button(kind: String, label: String, message: Msg) -> Element(Msg) {
  html.button(
    [
      attribute.classes([#("action-button", True), #(kind, True)]),
      event.on_click(message),
    ],
    [html.text(label)],
  )
}

fn stat_card(label: String, value: String) -> Element(Msg) {
  html.div(
    [attribute.classes([#("stat-card", True)])],
    [
      html.span([attribute.classes([#("stat-label", True)])], [html.text(label)]),
      html.strong([], [html.text(value)]),
    ],
  )
}

fn render_log_items(log: List(String), limit: Int) -> List(Element(Msg)) {
  case limit {
    0 -> []
    _ ->
      case log {
        [] -> []
        [entry, ..rest] -> [html.div([attribute.classes([#("log-entry", True)])], [html.text(entry)]), ..render_log_items(rest, limit - 1)]
      }
  }
}

fn play_card(model: Model, index: Int) -> Model {
  let current = current_player(model)

  case remove_at(current.hand, index, 0) {
    #(new_hand, Picked(card)) -> {
      let current = Player(..current, hand: new_hand)
      let model = set_current_player(model, current)
      let model = log_action(
        model,
        turn_name(model.turn) <> "が" <> land_name(card) <> "をプレイしました。",
      )

      case has_counter_cost(opponent_player(model).hand) {
        True -> Model(..model, prompt: CounterWindow(card))
        False -> resolve_play(model, card)
      }
    }

    _ -> model
  }
}

fn counter_with_island(model: Model, card: Land, index: Int) -> Model {
  let defender = opponent_player(model)

  case remove_at(defender.hand, index, 0) {
    #(hand_without_discard, Picked(discarded_card)) ->
      case remove_first(hand_without_discard, Island) {
        #(final_hand, Picked(island_card)) -> {
          let defender = Player(
            ..defender,
            hand: final_hand,
            graveyard: [discarded_card, island_card, ..defender.graveyard],
          )
          let model = set_opponent_player(model, defender)
          let model = log_action(
            model,
            turn_name(other_turn(model.turn))
              <> "が島と"
              <> land_name(discarded_card)
              <> "を捨て、"
              <> land_name(card)
              <> "を打ち消しました。",
          )

          end_turn(model)
        }

        _ -> model
      }

    _ -> model
  }
}

fn resolve_play(model: Model, card: Land) -> Model {
  let current = current_player(model)
  let current = Player(..current, battlefield: [card, ..current.battlefield])
  let model = set_current_player(model, current)

  case card {
    Plains ->
      case current.graveyard {
        [] ->
          finalize_after_action(
            log_and_prompt(
              model,
              turn_name(model.turn) <> "が平地を解決しましたが、墓地に対象がありません。",
              EndTurnReady,
            ),
          )

        _ ->
          log_and_prompt(
            model,
            turn_name(model.turn) <> "が平地を解決しました。",
            ChoosePlainsTarget(card),
          )
      }

    Island ->
      finalize_after_action(
        log_and_prompt(model, turn_name(model.turn) <> "が島を解決しました。", EndTurnReady),
      )

    Swamp ->
      case opponent_player(model).hand {
        [] ->
          finalize_after_action(
            log_and_prompt(
              model,
              turn_name(model.turn) <> "が沼を解決しましたが、相手の手札がありません。",
              EndTurnReady,
            ),
          )

        _ ->
          log_and_prompt(
            model,
            turn_name(model.turn) <> "が沼を解決しました。",
            ChooseSwampTarget(card),
          )
      }

    Mountain ->
      case battlefield_exists(model) {
        True ->
          log_and_prompt(
            model,
            turn_name(model.turn) <> "が山を解決しました。",
            ChooseMountainTarget(card),
          )
        False ->
          finalize_after_action(
            log_and_prompt(
              model,
              turn_name(model.turn) <> "が山を解決しましたが、戦場に対象がありません。",
              EndTurnReady,
            ),
          )
      }

    Forest ->
      case current.deck {
        [] ->
          finalize_after_action(
            log_and_prompt(
              model,
              turn_name(model.turn) <> "が森を解決しましたが、山札が空です。",
              EndTurnReady,
            ),
          )

        _ ->
          log_and_prompt(
            model,
            turn_name(model.turn) <> "が森を解決しました。",
            ChooseForestDraw(card),
          )
      }
  }
}

fn resolve_plains(model: Model, _card: Land, index: Int) -> Model {
  let current = current_player(model)

  case remove_at(current.graveyard, index, 0) {
    #(new_graveyard, Picked(returned_card)) -> {
      let current = Player(..current, graveyard: new_graveyard, hand: [returned_card, ..current.hand])
      let model = set_current_player(model, current)
      let model = log_action(
        model,
        turn_name(model.turn) <> "が平地で" <> land_name(returned_card) <> "を回収しました。",
      )

      finalize_after_action(Model(..model, prompt: EndTurnReady))
    }

    _ -> model
  }
}

fn resolve_swamp(model: Model, _card: Land, index: Int) -> Model {
  let opponent = opponent_player(model)

  case remove_at(opponent.hand, index, 0) {
    #(new_hand, Picked(discarded_card)) -> {
      let opponent = Player(..opponent, hand: new_hand, graveyard: [discarded_card, ..opponent.graveyard])
      let model = set_opponent_player(model, opponent)
      let model = log_action(
        model,
        turn_name(other_turn(model.turn)) <> "が沼で" <> land_name(discarded_card) <> "を捨てました。",
      )

      finalize_after_action(Model(..model, prompt: EndTurnReady))
    }

    _ -> model
  }
}

fn resolve_mountain(model: Model, _card: Land, owner: Turn, index: Int) -> Model {
  let target_player = player_by_turn(model, owner)

  case remove_at(target_player.battlefield, index, 0) {
    #(new_battlefield, Picked(destroyed_card)) -> {
      let target_player = Player(
        ..target_player,
        battlefield: new_battlefield,
        graveyard: [destroyed_card, ..target_player.graveyard],
      )
      let model = set_player(model, owner, target_player)
      let model = log_action(
        model,
        turn_name(model.turn)
          <> "が山で"
          <> turn_name(owner)
          <> "の"
          <> land_name(destroyed_card)
          <> "を破壊しました。",
      )

      finalize_after_action(Model(..model, prompt: EndTurnReady))
    }

    _ -> model
  }
}

fn resolve_forest(model: Model, _card: Land) -> Model {
  let current = current_player(model)

  case current.deck {
    [] ->
      finalize_after_action(
        log_and_prompt(model, turn_name(model.turn) <> "は山札が空で引けませんでした。", EndTurnReady),
      )

    [drawn_card, ..rest] -> {
      let current = Player(..current, deck: rest, hand: [drawn_card, ..current.hand])
      let model = set_current_player(model, current)
      let model = log_action(
        model,
        turn_name(model.turn) <> "が森で" <> land_name(drawn_card) <> "を引きました。",
      )

      finalize_after_action(Model(..model, prompt: EndTurnReady))
    }
  }
}

fn end_turn(model: Model) -> Model {
  case winner(model) {
    HasWinner(turn) -> Model(..model, prompt: GameOver(turn))
    NoWinner -> {
      let next_turn = other_turn(model.turn)
      let model = Model(
        ..model,
        turn: next_turn,
        prompt: ChoosePlay,
        turn_number: model.turn_number + 1,
      )

      begin_turn(model)
    }
  }
}

fn begin_turn(model: Model) -> Model {
  let model = log_action(model, turn_name(model.turn) <> "のターン開始。")
  draw_turn_card(model)
}

fn draw_turn_card(model: Model) -> Model {
  let current = current_player(model)

  case current.deck {
    [] ->
      log_action(
        model,
        turn_name(model.turn) <> "は山札が空のため、ターン開始時に引けませんでした。",
      )

    [drawn_card, ..rest] -> {
      let current = Player(..current, deck: rest, hand: [drawn_card, ..current.hand])
      let model = set_current_player(model, current)
      log_action(
        model,
        turn_name(model.turn) <> "がターン開始時に" <> land_name(drawn_card) <> "を引きました。",
      )
    }
  }
}

fn finalize_after_action(model: Model) -> Model {
  case winner(model) {
    HasWinner(turn) -> Model(..model, prompt: GameOver(turn))
    NoWinner -> model
  }
}

fn log_and_prompt(model: Model, entry: String, prompt: Prompt) -> Model {
  let model = log_action(model, entry)
  Model(..model, prompt: prompt)
}

fn winner(model: Model) -> Winner {
  case has_all_five(model.player_one.battlefield) {
    True -> HasWinner(PlayerOne)
    False ->
      case has_all_five(model.player_two.battlefield) {
        True -> HasWinner(PlayerTwo)
        False -> NoWinner
      }
  }
}

fn has_all_five(cards: List(Land)) -> Bool {
  contains_land(cards, Plains)
    && contains_land(cards, Island)
    && contains_land(cards, Swamp)
    && contains_land(cards, Mountain)
    && contains_land(cards, Forest)
}

fn battlefield_exists(model: Model) -> Bool {
  list.length(model.player_one.battlefield) + list.length(model.player_two.battlefield) > 0
}

fn has_counter_cost(cards: List(Land)) -> Bool {
  contains_land(cards, Island) && count_non_island(cards) > 0
}

fn count_non_island(cards: List(Land)) -> Int {
  case cards {
    [] -> 0
    [card, ..rest] ->
      case card == Island {
        True -> count_non_island(rest)
        False -> 1 + count_non_island(rest)
      }
  }
}

fn contains_land(cards: List(Land), target: Land) -> Bool {
  case cards {
    [] -> False
    [card, ..rest] ->
      case card == target {
        True -> True
        False -> contains_land(rest, target)
      }
  }
}

fn remove_first(cards: List(Land), target: Land) -> #(List(Land), PickResult(Land)) {
  case cards {
    [] -> #([], NotPicked)
    [card, ..rest] ->
      case card == target {
        True -> #(rest, Picked(card))
        False -> {
          let #(new_rest, pick) = remove_first(rest, target)
          #([card, ..new_rest], pick)
        }
      }
  }
}

fn remove_at(cards: List(Land), target_index: Int, current_index: Int) -> #(List(Land), PickResult(Land)) {
  case cards {
    [] -> #([], NotPicked)
    [card, ..rest] ->
      case current_index == target_index {
        True -> #(rest, Picked(card))
        False -> {
          let #(new_rest, pick) = remove_at(rest, target_index, current_index + 1)
          #([card, ..new_rest], pick)
        }
      }
  }
}

fn current_player(model: Model) -> Player {
  player_by_turn(model, model.turn)
}

fn opponent_player(model: Model) -> Player {
  player_by_turn(model, other_turn(model.turn))
}

fn player_by_turn(model: Model, turn: Turn) -> Player {
  case turn {
    PlayerOne -> model.player_one
    PlayerTwo -> model.player_two
  }
}

fn set_current_player(model: Model, player: Player) -> Model {
  set_player(model, model.turn, player)
}

fn set_opponent_player(model: Model, player: Player) -> Model {
  set_player(model, other_turn(model.turn), player)
}

fn set_player(model: Model, turn: Turn, player: Player) -> Model {
  case turn {
    PlayerOne -> Model(..model, player_one: player)
    PlayerTwo -> Model(..model, player_two: player)
  }
}

fn log_action(model: Model, entry: String) -> Model {
  Model(..model, log: [entry, ..model.log])
}

fn draw_opening_hand(player: Player, count: Int) -> Player {
  case count {
    0 -> player
    _ ->
      case player.deck {
        [] -> player
        [card, ..rest] -> {
          let player = Player(..player, deck: rest, hand: [card, ..player.hand])
          draw_opening_hand(player, count - 1)
        }
      }
  }
}

fn new_player(turn: Turn) -> Player {
  case turn {
    PlayerOne -> Player(
      name: "プレイヤー1",
      deck: repeated_deck([Plains, Island, Swamp, Mountain, Forest], 6, []),
      hand: [],
      battlefield: [],
      graveyard: [],
    )

    PlayerTwo -> Player(
      name: "プレイヤー2",
      deck: repeated_deck([Forest, Mountain, Swamp, Island, Plains], 6, []),
      hand: [],
      battlefield: [],
      graveyard: [],
    )
  }
}

fn repeated_deck(cycle: List(Land), times: Int, acc: List(Land)) -> List(Land) {
  case times {
    0 -> acc
    _ -> repeated_deck(cycle, times - 1, append_list(cycle, acc))
  }
}

fn append_list(items: List(Land), acc: List(Land)) -> List(Land) {
  case items {
    [] -> acc
    [card, ..rest] -> [card, ..append_list(rest, acc)]
  }
}

fn other_turn(turn: Turn) -> Turn {
  case turn {
    PlayerOne -> PlayerTwo
    PlayerTwo -> PlayerOne
  }
}

fn turn_name(turn: Turn) -> String {
  case turn {
    PlayerOne -> "プレイヤー1"
    PlayerTwo -> "プレイヤー2"
  }
}

fn land_name(land: Land) -> String {
  case land {
    Plains -> "平地"
    Island -> "島"
    Swamp -> "沼"
    Mountain -> "山"
    Forest -> "森"
  }
}

fn land_class(land: Land) -> String {
  case land {
    Plains -> "plains"
    Island -> "island"
    Swamp -> "swamp"
    Mountain -> "mountain"
    Forest -> "forest"
  }
}

fn player_panel_class(active: Bool) -> String {
  case active {
    True -> "panel-active"
    False -> "panel-idle"
  }
}
