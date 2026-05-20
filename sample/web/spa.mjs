import * as $int from "./gleam_stdlib/gleam/int.mjs";
import * as $lustre from "./lustre.mjs";
import * as $element from "./lustre/lustre/element.mjs";
import * as $html from "./lustre/lustre/element/html.mjs";
import * as $event from "./lustre/lustre/event.mjs";
import { toList, CustomType as $CustomType } from "./gleam.mjs";

export class Home extends $CustomType {}
export const Page$Home = () => new Home();
export const Page$isHome = (value) => value instanceof Home;

export class Counter extends $CustomType {}
export const Page$Counter = () => new Counter();
export const Page$isCounter = (value) => value instanceof Counter;

export class Model extends $CustomType {
  constructor(page, count) {
    super();
    this.page = page;
    this.count = count;
  }
}
export const Model$Model = (page, count) => new Model(page, count);
export const Model$isModel = (value) => value instanceof Model;
export const Model$Model$page = (value) => value.page;
export const Model$Model$0 = (value) => value.page;
export const Model$Model$count = (value) => value.count;
export const Model$Model$1 = (value) => value.count;

export class GoHome extends $CustomType {}
export const Msg$GoHome = () => new GoHome();
export const Msg$isGoHome = (value) => value instanceof GoHome;

export class GoCounter extends $CustomType {}
export const Msg$GoCounter = () => new GoCounter();
export const Msg$isGoCounter = (value) => value instanceof GoCounter;

export class Inc extends $CustomType {}
export const Msg$Inc = () => new Inc();
export const Msg$isInc = (value) => value instanceof Inc;

export class Dec extends $CustomType {}
export const Msg$Dec = () => new Dec();
export const Msg$isDec = (value) => value instanceof Dec;

export class Reset extends $CustomType {}
export const Msg$Reset = () => new Reset();
export const Msg$isReset = (value) => value instanceof Reset;

function init(_) {
  return new Model(new Home(), 0);
}

function update(model, msg) {
  if (msg instanceof GoHome) {
    return new Model(new Home(), model.count);
  } else if (msg instanceof GoCounter) {
    return new Model(new Counter(), model.count);
  } else if (msg instanceof Inc) {
    return new Model(model.page, model.count + 1);
  } else if (msg instanceof Dec) {
    return new Model(model.page, model.count - 1);
  } else {
    return new Model(model.page, 0);
  }
}

function view(model) {
  return $html.div(
    toList([]),
    toList([
      $html.nav(
        toList([]),
        toList([
          $html.button(toList([$event.on_click(new GoHome())]), toList([$html.text("Home")])),
          $html.button(toList([$event.on_click(new GoCounter())]), toList([$html.text("Counter")])),
        ]),
      ),
      (() => {
        let $ = model.page;
        if ($ instanceof Home) {
          return $html.section(
            toList([]),
            toList([
              $html.h1(toList([]), toList([$html.text("Welcome")])),
              $html.p(toList([]), toList([$html.text("This is a Lustre SPA demo.")])),
            ]),
          );
        } else {
          return $html.section(
            toList([]),
            toList([
              $html.h1(toList([]), toList([$html.text("Counter")])),
              $html.p(toList([]), toList([$html.text($int.to_string(model.count))])),
              $html.div(
                toList([]),
                toList([
                  $html.button(toList([$event.on_click(new Dec())]), toList([$html.text("－")])),
                  $html.button(toList([$event.on_click(new Inc())]), toList([$html.text("＋")])),
                  $html.button(
                    toList([$event.on_click(new Reset())]),
                    toList([$html.text("リセット")]),
                  ),
                ]),
              ),
            ]),
          );
        }
      })(),
    ]),
  );
}

export function app() {
  return $lustre.simple(init, update, view);
}
