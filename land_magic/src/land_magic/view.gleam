import gleam/int
import gleam/list
import land_magic/domain.{land_class, land_name, other_turn, turn_name}
import land_magic/state.{current_player, opponent_player}
import land_magic/types.{
  type Land,
  type Turn,
  type Player,
  type Prompt,
  type Model,
  type Msg,
  Island,
  PlayerOne,
  PlayerTwo,
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
}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn render(model: Model) -> Element(Msg) {
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
      html.main(
        [attribute.classes([#("board-layout", True)])],
        [
          html.div(
            [attribute.classes([#("playfield", True)])],
            [
              player_panel(model.player_two, model.turn == PlayerTwo, True),
              player_panel(model.player_one, model.turn == PlayerOne, False),
            ],
          ),
          html.aside(
            [attribute.classes([#("sidebar", True)])],
            [
              html.section(
                [
                  attribute.classes([
                    #("panel", True),
                    #("settings-panel", True),
                    #(prompt_panel_class(model.prompt), True),
                  ]),
                ],
                [
                  html.div([attribute.classes([#("panel-head", True)])], [
                    html.h2([], [html.text(prompt_title(model.prompt, model.turn))]),
                    html.p([], [html.text(prompt_body(model))]),
                  ]),
                  prompt_controls(model),
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
          ),
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
            "相手は島と他の1枚を捨てて、" <> land_name(card) <> "を打ち消せます。",
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
          html.text(
            "沼は" <> turn_name(other_turn(model.turn)) <> "に手札を1枚捨てさせます。",
          ),
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

fn player_panel(player: Player, active: Bool, top: Bool) -> Element(Msg) {
  html.section(
    [
      attribute.classes([
        #("panel", True),
        #("player-panel", True),
        #(player_panel_class(active), True),
        #(player_panel_position_class(top), True),
      ]),
    ],
    [
      html.div([attribute.classes([#("panel-head", True)])], [
        html.div([attribute.classes([#("title-row", True)])], [
          html.h2([], [html.text(player.name)]),
          case active {
            True ->
              html.span(
                [attribute.classes([#("badge", True), #("badge-active", True)])],
                [html.text("手番中")],
              )

            False -> html.span([attribute.classes([#("badge", True)])], [html.text("待機中")])
          },
        ]),
        html.p([], [html.text(zone_summary(player))]),
      ]),
      html.div(
        [attribute.classes([#("zone-grid", True), #(player_board_class(top), True)])],
        case top {
          True -> [
            zone_view("山札", player.deck, "deck-zone"),
            zone_view("手札", player.hand, "hand-zone"),
            zone_view("墓地", player.graveyard, "graveyard-zone"),
            zone_view("戦場", player.battlefield, "battlefield-zone"),
          ]

          False -> [
            zone_view("戦場", player.battlefield, "battlefield-zone"),
            zone_view("手札", player.hand, "hand-zone"),
            zone_view("山札", player.deck, "deck-zone"),
            zone_view("墓地", player.graveyard, "graveyard-zone"),
          ]
        },
      ),
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
    [card, ..rest] -> [
      land_action_button("play-card", card, land_name(card), PlayCard(index)),
      ..render_play_buttons(rest, index + 1)
    ]
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
    [card, ..rest] -> [
      land_action_button("graveyard-card", card, land_name(card), ReturnFromGraveyard(index)),
      ..render_graveyard_buttons(rest, index + 1)
    ]
  }
}

fn render_discard_buttons(cards: List(Land), index: Int) -> List(Element(Msg)) {
  case cards {
    [] -> []
    [card, ..rest] -> [
      land_action_button("discard-card", card, land_name(card), DiscardOpponentCard(index)),
      ..render_discard_buttons(rest, index + 1)
    ]
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
        [entry, ..rest] -> [
          html.div([attribute.classes([#("log-entry", True)])], [html.text(entry)]),
          ..render_log_items(rest, limit - 1)
        ]
      }
  }
}

fn player_panel_class(active: Bool) -> String {
  case active {
    True -> "panel-active"
    False -> "panel-idle"
  }
}

fn player_board_class(top: Bool) -> String {
  case top {
    True -> "top-board"
    False -> "bottom-board"
  }
}

fn player_panel_position_class(top: Bool) -> String {
  case top {
    True -> "player-panel-top"
    False -> "player-panel-bottom"
  }
}
