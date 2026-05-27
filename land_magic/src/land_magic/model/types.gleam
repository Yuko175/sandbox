/// 概要: ゲームで使う土地カードの種類です。
/// 引数: この型は値そのものが種類を表すので、追加の引数はありません。
/// 戻り値: どの土地かを表す値を扱います。
pub type Land {
  Plains
  Island
  Swamp
  Mountain
  Forest
}

/// 概要: どちらのプレイヤーの手番かを表します。
/// 引数: この型は値そのものが手番を表すので、追加の引数はありません。
/// 戻り値: プレイヤー1かプレイヤー2の手番を扱います。
pub type Turn {
  PlayerOne
  PlayerTwo
}

/// 概要: 1人分のプレイヤー情報をまとめた型です。
/// 引数: この型は名前と各領域のカード一覧を持ちます。
/// 戻り値: プレイヤーの状態を1つの値として扱います。
pub type Player {
  Player(
    name: String,
    deck: List(Land),
    hand: List(Land),
    battlefield: List(Land),
    graveyard: List(Land),
  )
}

/// 概要: 画面で次に何をするかを表します。
/// 引数: この型は現在の操作内容を値として保持します。
/// 戻り値: 各操作モードを表す値を扱います。
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

/// 概要: ゲーム全体の状態をまとめた型です。
/// 引数: この型は両プレイヤー、手番、表示状態、ログなどを保持します。
/// 戻り値: 画面とゲーム進行に必要なすべての情報を1つにまとめます。
pub type Model {
  Model(
    player_one: Player,
    player_two: Player,
    turn: Turn,
    prompt: Prompt,
    log: List(String),
    prompt_message: String,
    turn_number: Int,
  )
}

/// 概要: 何かを取り出せたかどうかを表す結果型です。
/// 引数: `a` は取り出した値の型です。
/// 戻り値: 取り出せた値または失敗を表します。
pub type PickResult(a) {
  Picked(a)
  NotPicked
}

/// 概要: 勝者の有無を表します。
/// 引数: この型は現在の勝敗状態を値として持ちます。
/// 戻り値: 勝者がいないか、どちらかが勝っているかを表します。
pub type Winner {
  NoWinner
  HasWinner(Turn)
}

/// 概要: 画面やゲームから届く操作メッセージです。
/// 引数: この型は操作内容ごとのデータを値として保持します。
/// 戻り値: 画面イベントやゲーム処理の種類を表します。
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