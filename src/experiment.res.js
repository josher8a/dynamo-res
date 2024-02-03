// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Js_exn from "rescript/lib/es6/js_exn.js";
import * as Caml_exceptions from "rescript/lib/es6/caml_exceptions.js";
import * as Caml_js_exceptions from "rescript/lib/es6/caml_js_exceptions.js";

var ReturnError = /* @__PURE__ */Caml_exceptions.create("Experiment.ReturnError");

function orReturn(x) {
  if (x.TAG === "Ok") {
    return x._0;
  }
  throw {
        RE_EXN_ID: ReturnError,
        _1: x._0,
        Error: new Error()
      };
}

function handle(rutine) {
  try {
    return rutine();
  }
  catch (raw_e){
    var e = Caml_js_exceptions.internalToOCamlException(raw_e);
    if (e.RE_EXN_ID === ReturnError) {
      return {
              TAG: "Error",
              _0: e._1
            };
    }
    if (e.RE_EXN_ID === Js_exn.$$Error) {
      throw e._1;
    }
    throw e;
  }
}

var ReturnError$1 = /* @__PURE__ */Caml_exceptions.create("Experiment.Handler.ReturnError");

function orReturn$1(x) {
  if (x.TAG === "Ok") {
    return x._0;
  }
  throw {
        RE_EXN_ID: ReturnError$1,
        _1: x._0,
        Error: new Error()
      };
}

function handle$1(rutine) {
  try {
    return rutine();
  }
  catch (raw_e){
    var e = Caml_js_exceptions.internalToOCamlException(raw_e);
    if (e.RE_EXN_ID === ReturnError$1) {
      return {
              TAG: "Error",
              _0: e._1
            };
    }
    if (e.RE_EXN_ID === Js_exn.$$Error) {
      throw e._1;
    }
    throw e;
  }
}

var Handler = {
  ReturnError: ReturnError$1,
  orReturn: orReturn$1,
  handle: handle$1
};

function may_fail() {
  return {
          TAG: "Ok",
          _0: 4
        };
}

function compose_may_fail() {
  return handle(function () {
              var x = 4;
              var y = 4;
              return {
                      TAG: "Ok",
                      _0: String(x + y | 0)
                    };
            });
}

export {
  ReturnError ,
  orReturn ,
  handle ,
  Handler ,
  may_fail ,
  compose_may_fail ,
}
/* No side effect */
