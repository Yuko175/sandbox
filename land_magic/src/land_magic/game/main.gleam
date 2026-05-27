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

/// 概要: ゲームの初期状態を作ります。
/// 引数: `_args` は起動引数ですが、このゲームでは使いません。
/// 戻り値: 初期化されたゲーム状態を返します。
pub fn init(_args: Nil) -> Model {
  let player_one = setup.draw_opening_hand(setup.new_player(PlayerOne), 4)
  let player_two = setup.draw_opening_hand(setup.new_player(PlayerTwo), 4)
  let hand1 = "プレイヤー1の手札: " <> names_to_string(player_one.hand)
  let hand2 = "プレイヤー2の手札: " <> names_to_string(player_two.hand)

  let model = Model(
    player_one: player_one,
    player_two: player_two,
    turn: PlayerOne,
    prompt: DrawTurnCard,
    log: [
      "新しいゲームを開始しました。",
      "手札は公開され、すべての選択は手動です。",
      hand1,
      hand2,
    ],
    prompt_message: "",
    turn_number: 1,
  )

  begin_turn(model)
}

/// 概要: 画面操作やゲームイベントを受けて状態を更新します。
/// 引数: `model` に現在の状態を渡します。
/// 引数: `msg` に発生した操作内容を渡します。
/// 戻り値: 操作後の新しいゲーム状態を返します。
pub fn update(model: Model, msg: Msg) -> Model {
  case msg {
    // ゲームの最初からやり直す。
    ResetGame -> init(Nil)

    // 手札からカードを出す操作。
    PlayCard(index) ->
      case model.prompt {
        ChoosePlay -> play_card(model, index)
        _ -> model
      }

    // 島の打ち消し選択を始める。
    BeginCounterSelection ->
      case model.prompt {
        CounterWindow(card) -> island_card.begin_counter_selection(model, card)
        CounterSelecting(card, _) -> island_card.begin_counter_selection(model, card)
        _ -> model
      }

    // 打ち消し用の2枚目を選ぶ。
    SelectCounterCard(index) ->
      case model.prompt {
        CounterSelecting(card, _) -> island_card.select_counter_card(model, card, index)
        _ -> model
      }

    // 打ち消しをあきらめて、出されたカードをそのまま解決する。
    PassCounter ->
      case model.prompt {
        CounterWindow(card) -> resolve_played_card(island_card.pass_counter(model, card), card)
        CounterSelecting(card, _) -> resolve_played_card(island_card.pass_counter(model, card), card)
        _ -> model
      }

    // 平地の効果で、自分の墓地からカードを戻す。
    ReturnFromGraveyard(index) ->
      case model.prompt {
        ChoosePlainsTarget(_) -> plains_card.resolve_target(model, index)
        _ -> model
      }

    // 沼の効果で、相手の手札からカードを捨てる。
    DiscardOpponentCard(index) ->
      case model.prompt {
        ChooseSwampTarget(_) -> swamp_card.resolve_target(model, index)
        _ -> model
      }

    // 山の効果で、相手の戦場のカードを破壊する。
    DestroyFromBattlefield(owner, index) ->
      case model.prompt {
        ChooseMountainTarget(_) -> mountain_card.resolve_target(model, owner, index)
        _ -> model
      }

    // 森の効果で、山札から1枚引く。
    DrawForForest ->
      case model.prompt {
        ChooseForestDraw(_) -> forest_card.resolve_draw(model)
        _ -> model
      }

    // ターン開始のドロー、または森のドロー処理。
    DrawFromDeck ->
      case model.prompt {
        DrawTurnCard -> {
          let model = setup.draw_turn_card(model)
          Model(..model, prompt: ChoosePlay, prompt_message: "")
        }

        ChooseForestDraw(_) -> forest_card.resolve_draw(model)
        _ -> model
      }

    // ターンを終えるボタン。
    FinishTurn ->
      case model.prompt {
        ChoosePlay -> end_turn(model)
        ChooseMountainTarget(_) -> end_turn(model)
        EndTurnReady -> end_turn(model)
        _ -> model
      }
  }
}

/// 概要: 手札からカードを1枚プレイします。
/// 引数: `model` に現在の状態を渡します。
/// 引数: `index` に手札の位置を渡します。
/// 戻り値: カードを出した後の新しい状態を返します。
fn play_card(model: Model, index: Int) -> Model {
  let current = current_player(model)

  // 手札の指定位置から1枚取り出す。
  case rules.remove_at(current.hand, index, 0) {
    #(new_hand, Picked(card)) -> {
      // まず手札を減らす。
      let current = Player(..current, hand: new_hand)
      let model = set_current_player(model, current)
      // 出したカードをログに残す。
      let model = rules.log_action(
        model,
        turn_name(model.turn) <> "が" <> land_name(card) <> "をプレイしました。",
      )

      // 相手に打ち消しできる手札があるかを確認する。
      case rules.has_counter_cost(opponent_player(model).hand) {
        True -> {
          // 戦場にカードを置いたうえで、相手の打ち消し待ちに切り替える。
          let current = Player(..current, battlefield: [card, ..current.battlefield])
          let model = set_current_player(model, current)

          Model(..model, turn: other_turn(model.turn), prompt: CounterWindow(card), prompt_message: "")
        }
        False -> {
          // 打ち消しできなくても、カードは戦場に置いてから相手の手番へ進む。
          let current = Player(..current, battlefield: [card, ..current.battlefield])
          let model = set_current_player(model, current)

          Model(..model, turn: other_turn(model.turn), prompt: CounterWindow(card), prompt_message: "")
        }
      }
    }

    _ -> model
  }
}

/// 概要: 現在のターンを終えて次のプレイヤーに渡します。
/// 引数: `model` に現在の状態を渡します。
/// 戻り値: 勝敗確認後の次ターン状態を返します。
fn end_turn(model: Model) -> Model {
  // 先に勝敗条件を確認する。
  case rules.winner(model) {
    HasWinner(turn) -> Model(..model, prompt: GameOver(turn))
    NoWinner -> {
      // 勝者がいなければ、相手のターンへ進める。
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

/// 概要: プレイした土地カードの効果を解決します。
/// 引数: `model` に現在の状態を渡します。
/// 引数: `card` に出した土地カードを渡します。
/// 戻り値: 各カード効果を反映した新しい状態を返します。
fn resolve_played_card(model: Model, card: Land) -> Model {
  // 出した土地の種類ごとに、対応する効果へ分岐する。
  case card {
    Plains -> plains_card.resolve_on_play(model, card)
    Island -> island_card.resolve_on_play(model, card)
    Swamp -> swamp_card.resolve_on_play(model, card)
    Mountain -> mountain_card.resolve_on_play(model, card)
    Forest -> forest_card.resolve_on_play(model, card)
  }
}

/// 概要: 新しいターンの開始処理を行います。
/// 引数: `model` に現在の状態を渡します。
/// 戻り値: ターン開始ログと表示状態を反映した新しい状態を返します。
fn begin_turn(model: Model) -> Model {
  // ターン開始の記録を残して、山札を引く画面に戻す。
  let model = rules.log_action(model, turn_name(model.turn) <> "のターン開始。")
  Model(..model, prompt: DrawTurnCard, prompt_message: "")
}

/// 概要: カード一覧を見やすい文字列にします。
/// 引数: `cards` に土地カード一覧を渡します。
/// 戻り値: カード名をカンマ区切りにした文字列を返します。
fn names_to_string(cards: List(Land)) -> String {
  case cards {
    [] -> ""
    [card] -> land_name(card)
    // 2枚以上あるときは、先頭を取り出して残りを再帰的につなぐ。
    [card, ..rest] -> land_name(card) <> ", " <> names_to_string(rest)
  }
}
