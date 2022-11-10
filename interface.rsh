"reach 0.1";
"use strict";
// -----------------------------------------------
// Name: KINN Base (starter)
// Version: 0.1.0 - starter initial
// Requires Reach v0.1.11-rc7 (27cb9643) or later
// ----------------------------------------------

import {
  State as BaseState,
  Params as BaseParams,
  view,
  baseState,
  baseEvents
} from "@KinnFoundation/base#base-v0.1.11r4:interface.rsh";

// CONSTANTS

const SERIAL_VER = 0;

// TYPES

export const StarterState = Struct([
  /* add your state here */
]);

/***/

const MToken = Maybe(Token);

const Bals = Struct([
  ["A", UInt],
  ["B", UInt],
]);

const ProtoInfo = Struct([
  ["lpFee", UInt],
  ["protoFee", UInt],
  ["totFee", UInt],
  ["protoAddr", Address],
  ["locked", Bool],
]);

const PoolState = Struct([
  ["liquidityToken", Token],
  ["lptBals", Bals],
  ["poolBals", Bals],
  ["protoInfo", ProtoInfo],
  ["protoBals", Bals],
  ["tokA", UInt],
  ["tokB", MToken],
]);

/***/

export const State = Struct([
  //...Struct.fields(BaseState),
  ...Struct.fields(PoolState),
]);

export const StarterParams = Object({
  rCtc: Contract,
});

export const Params = Object({
  ...Object.fields(BaseParams),
  ...Object.fields(StarterParams),
});

// FUN

const fState = (State) => Fun([], State);

// REMOTE FUN

/***/
const rPInfo = (ctc) => {
  const r = remote(ctc, { Info: Fun([], PoolState) });
  return r.Info();
};

export const rState = (ctc, State) => {
  const r = remote(ctc, { state: fState(State) });
  return r.state();
};

// CONTRACT

export const Event = () => [Events({ ...baseEvents })];
export const Participants = () => [
  Participant("Manager", {
    getParams: Fun([], Params),
  }),
  Participant("Relay", {}),
];
export const Views = () => [View(view(State))];
export const Api = () => [];
export const App = (map) => {
  const [{ amt, ttl }, [addr, _], [Manager, Relay], [v], _, [e]] = map;
  Manager.only(() => {
    const { rCtc } = declassify(interact.getParams());
  });
  Manager.publish(rCtc)
    .pay(amt + SERIAL_VER)
    .timeout(relativeTime(ttl), () => {
      Anybody.publish();
      commit();
      exit();
    });
  transfer(amt + SERIAL_VER).to(addr);
  e.appLaunch();
  commit();
  Relay.publish();
  const initialState = {
    ...baseState(Manager),
    ...Struct.toObject(rPInfo(rCtc)),
  };
  v.state.set(State.fromObject(initialState));
  e.appClose();
  commit();
  Relay.publish();
  commit();
  exit();
};
// ----------------------------------------------
