"reach 0.1";
"use strict";
// -----------------------------------------------
// Name: Humble Pool
// Version: 0.1.1 - fix parse issue
// Requires Reach v0.1.11-rc7 (27cb9643) or later
// ----------------------------------------------

import {
  Params as BaseParams,
  MToken
} from "@KinnFoundation/base#base-v0.1.11r16:interface.rsh";

// TYPES

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

export const State = Struct([...Struct.fields(PoolState)]);

export const Params = Object({
  ...Object.fields(BaseParams),
});

// REMOTE FUN

export const rPInfo = (ctc) => {
  const r = remote(ctc, { Info: Fun([], PoolState) });
  return r.Info();
};

// CONTRACT

export const Event = () => [];
export const Participants = () => [];
export const Views = () => [];
export const Api = () => [];
export const App = (_) => {
  Anybody.publish();
  commit();
  exit();
};
// ----------------------------------------------
