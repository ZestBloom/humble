"reach 0.1";
"use strict";
// -----------------------------------------------
// Name: Humble (PoC)
// Version: 0.1.0 - poc initial
// Requires Reach v0.1.11-rc7 (27cb9643) or later
// ----------------------------------------------

import {
  Params as BaseParams,
  State as BaseState,
  view,
  baseState,
  baseEvents,
  max,
  min
} from "@KinnFoundation/base#base-v0.1.11r16:interface.rsh";

import { rPInfo } from "@ZestBloom/humble#humble-v0.1.11r1:interface.rsh";

// CONSTANTS

const SERIAL_VER = 0;

// TYPES

const StarterState = Struct([
  ["rCtc", Contract],
  ["tokenAmount", UInt],
  ["A", UInt],
  ["B", UInt],
  ["C", UInt],
  ["D", UInt],
  ["E", UInt],
  ["F", UInt],
]);

export const State = Struct([
  ...Struct.fields(BaseState),
  ...Struct.fields(StarterState),
]);

const StarterParams = Object({
  tokenAmount: UInt,
  rCtc: Contract,
});

export const Params = Object({
  ...Object.fields(BaseParams),
  ...Object.fields(StarterParams),
});

// FUN

const fTouch = Fun([Address, UInt, UInt], Null);
const fCancel = Fun([], Null);

// API

const api = {
  touch: fTouch,
  cancel: fCancel,
};

// CONTRACT

export const Event = () => [Events({ ...baseEvents })];
export const Participants = () => [
  Participant("Manager", {
    getParams: Fun([], Params),
  })
];
export const Views = () => [View(view(State))];
export const Api = () => [API(api)];
export const App = (map) => {
  const [{ amt, ttl, tok0: token }, [addr, _], [Manager], [v], [a], [e]] =
    map;
  Manager.only(() => {
    const { rCtc, tokenAmount } = declassify(interact.getParams());
  });
  Manager.publish(rCtc, tokenAmount)
    .pay([amt + SERIAL_VER, [tokenAmount, token]])
    .timeout(relativeTime(ttl), () => {
      Anybody.publish();
      commit();
      exit();
    });
  transfer([amt + SERIAL_VER]).to(addr);
  e.appLaunch();
  const initialPInfo = rPInfo(rCtc);
  const initialState = {
    ...baseState(Manager),
    rCtc,
    tokenAmount,
    A: initialPInfo.poolBals.A,
    B: initialPInfo.poolBals.B,
    C: 0,
    D: 0,
    E: 0,
    F: 0,
  };
  const [s] = parallelReduce([initialState])
    .define(() => {
      v.state.set(State.fromObject(s));
    })
    .invariant(balance() == 0)
    .invariant(implies(!s.closed, balance(token) == s.tokenAmount))
    .invariant(implies(s.closed, balance(token) == 0))
    .while(!s.closed)
    .api_(a.touch, (ADDR, TA1, TB2) => {
      check(s.tokenAmount > 0, "No tokens left");
      return [
        TA1,
        (k) => {
          k(null);

          const RATE = 4; // 1%
          const FEE = (TA1 * RATE) / 400;

          const REM = TA1 - FEE;

          const TB0 = 150_000; // 0.15 USD
          const TU0 = 1_000_000; // 1 DEC6

          const pInfo = rPInfo(rCtc);
          const poolBals = pInfo.poolBals;
          const { A: TAP, B: TBP } = poolBals;

          const TA3 = muldiv(TB0, max(TAP, 1), max(TBP, 1)); // ALGO per 0.15USD,

          const precision = UInt.max;

          const TB1 = UInt(
            (UInt256(REM) * UInt256(precision)) /
              UInt256(TA3) /
              UInt256(precision),
            false
          );

          const TB3 = min(TB1, TB2);

          if (TB3 * TU0 <= s.tokenAmount && TB3 > 0) {
            const TA2 = REM - TB3 * TA3; // change to return to sender for exchange
            transfer([REM - TA2]).to(s.manager); // payment to manager
            transfer([[TB3 * TU0, token]]).to(ADDR); // token exchange
            transfer([TA2]).to(this); // change to signer
            transfer([FEE]).to(addr); // fee to launcher
            return [
              {
                ...s,
                tokenAmount: s.tokenAmount - TB3 * TU0,
                A: TAP,
                B: TBP,
                C: TB1,
                D: TA2,
                E: TA3,
                F: FEE
              },
            ];
          } else {
            transfer([TA1]).to(this);
            return [s];
          }
        },
      ];
    })
    .api_(a.cancel, () => {
      return [
        (k) => {
          k(null);
          transfer([[s.tokenAmount, token]]).to(s.manager);
          return [{ ...s, closed: true, tokenAmount: 0 }];
        },
      ];
    })
    .timeout(false);
  commit();
  exit();
};
// ----------------------------------------------
