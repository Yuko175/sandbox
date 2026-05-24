pub type Land {
  Plains
  Island
  Swamp
  Mountain
  Forest
}

pub type Turn {
  PlayerOne
  PlayerTwo
}

pub type Player {
  Player(
    name: String,
    deck: List(Land),
    hand: List(Land),
    battlefield: List(Land),
    graveyard: List(Land),
  )
}

pub type Prompt {
  DrawTurnCard
  ChoosePlay
  CounterWindow(card: Land)
  CounterSelecting(card: Land, selected: List(Int))
  ChoosePlainsTarget(card: Land)
  ChooseSwampTarget(card: Land)
  ChooseMountainTarget(card: Land)
  ChooseForestDraw(card: Land)
  EndTurnReady
  GameOver(winner: Turn)
}

pub type Model {
  Model(
    player_one: Player,
    player_two: Player,
    turn: Turn,
    prompt: Prompt,
    log: List(String),
    turn_number: Int,
  )
}

pub type PickResult(a) {
  Picked(a)
  NotPicked
}

pub type Winner {
  NoWinner
  HasWinner(Turn)
}

pub type Msg {
  ResetGame
  PlayCard(Int)
  BeginCounterSelection
  SelectCounterCard(Int)
  PassCounter
  ReturnFromGraveyard(Int)
  DiscardOpponentCard(Int)
  DestroyFromBattlefield(Turn, Int)
  DrawForForest
  DrawFromDeck
  FinishTurn
}