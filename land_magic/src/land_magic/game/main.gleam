import land_magic/game/cards/forest as forest_card
import land_magic/game/cards/island as island_card
import land_magic/game/cards/mountain as mountain_card
import land_magic/game/cards/plains as plains_card
import land_magic/game/cards/swamp as swamp_card
import land_magic/game/rules
import land_magic/game/setup
import land_magic/model/domain.{land_name, other_turn, turn_name}
import land_magic/model/types.{
  type Model,
  Model,
  type Msg,
  type Land,
  Plains,
  Island,
  Swamp,
  Mountain,
  Forest,
  PlayerOne,
  PlayerTwo,
  Player,
  DrawTurnCard,
  ChoosePlay,
  CounterWindow,
  CounterSelecting,
  ChoosePlainsTarget,
  ChooseSwampTarget,
  ChooseMountainTarget,
  ChooseForestDraw,
  EndTurnReady,
  GameOver,
  ResetGame,
  PlayCard,
  BeginCounterSelection,
  SelectCounterCard,
  PassCounter,
  ReturnFromGraveyard,
  DiscardOpponentCard,
  DestroyFromBattlefield,
  DrawForForest,
  DrawFromDeck,
  FinishTurn,
  Picked,
  HasWinner,
  NoWinner,
}
import land_magic/state/players.{current_player, opponent_player, set_current_player}

pub fn init(_args: Nil) -> Model {
  let player_one = setup.draw_opening_hand(setup.new_player(PlayerOne), 4)
  let player_two = setup.draw_opening_hand(setup.new_player(PlayerTwo), 4)

  let model = Model(
    player_one: player_one,
    player_two: player_two,
    turn: PlayerOne,
    prompt: DrawTurnCard,
    log: [
      "新しいゲームを開始しました。",
      "手札は公開され、すべての選択は手動です。",
    ],
    turn_number: 1,
  )

  begin_turn(model)
}

pub fn update(model: Model, msg: Msg) -> Model {
  case msg {
    ResetGame -> init(Nil)

    PlayCard(index) ->
      case model.prompt {
        ChoosePlay -> play_card(model, index)
        _ -> model
      }

    BeginCounterSelection ->
      case model.prompt {
        CounterWindow(card) -> island_card.begin_counter_selection(model, card)
        CounterSelecting(card, _) -> island_card.begin_counter_selection(model, card)
        _ -> model
      }

    SelectCounterCard(index) ->
      case model.prompt {
        CounterSelecting(card, _) -> island_card.select_counter_card(model, card, index)
        _ -> model
      }

    PassCounter ->
      case model.prompt {
        CounterWindow(card) -> resolve_played_card(island_card.pass_counter(model, card), card)
        CounterSelecting(card, _) -> resolve_played_card(island_card.pass_counter(model, card), card)
        _ -> model
      }

    ReturnFromGraveyard(index) ->
      case model.prompt {
        ChoosePlainsTarget(_) -> plains_card.resolve_target(model, index)
        _ -> model
      }

    DiscardOpponentCard(index) ->
      case model.prompt {
        ChooseSwampTarget(_) -> swamp_card.resolve_target(model, index)
        _ -> model
      }

    DestroyFromBattlefield(owner, index) ->
      case model.prompt {
        ChooseMountainTarget(_) -> mountain_card.resolve_target(model, owner, index)
        _ -> model
      }

    DrawForForest ->
      case model.prompt {
        ChooseForestDraw(_) -> forest_card.resolve_draw(model)
        _ -> model
      }

    DrawFromDeck ->
      case model.prompt {
        DrawTurnCard -> {
          let model = setup.draw_turn_card(model)
          Model(..model, prompt: ChoosePlay)
        }

        ChooseForestDraw(_) -> forest_card.resolve_draw(model)
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

fn play_card(model: Model, index: Int) -> Model {
  let current = current_player(model)

  case rules.remove_at(current.hand, index, 0) {
    #(new_hand, Picked(card)) -> {
      let current = Player(..current, hand: new_hand)
      let model = set_current_player(model, current)
      let model = rules.log_action(
        model,
        turn_name(model.turn) <> "が" <> land_name(card) <> "をプレイしました。",
      )

      case rules.has_counter_cost(opponent_player(model).hand) {
        True -> {
          let current = Player(..current, battlefield: [card, ..current.battlefield])
          let model = set_current_player(model, current)

          Model(..model, turn: other_turn(model.turn), prompt: CounterWindow(card))
        }
        False -> {
          let current = Player(..current, battlefield: [card, ..current.battlefield])
          let model = set_current_player(model, current)

          Model(..model, turn: other_turn(model.turn), prompt: CounterWindow(card))
        }
      }
    }

    _ -> model
  }
}

fn end_turn(model: Model) -> Model {
  case rules.winner(model) {
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

fn resolve_played_card(model: Model, card: Land) -> Model {
  case card {
    Plains -> plains_card.resolve_on_play(model, card)
    Island -> island_card.resolve_on_play(model, card)
    Swamp -> swamp_card.resolve_on_play(model, card)
    Mountain -> mountain_card.resolve_on_play(model, card)
    Forest -> forest_card.resolve_on_play(model, card)
  }
}

fn begin_turn(model: Model) -> Model {
  let model = rules.log_action(model, turn_name(model.turn) <> "のターン開始。")
  Model(..model, prompt: DrawTurnCard)
}
