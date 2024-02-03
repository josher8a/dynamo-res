// Generated by ReScript, PLEASE EDIT WITH CARE


function name(param_0) {
  return {
          TAG: "Name",
          _0: param_0
        };
}

function attributeValue(param_0) {
  return {
          TAG: "AttributeValue",
          _0: param_0
        };
}

function attributePath(param_0, param_1) {
  return {
          TAG: "AttributePath",
          _0: param_0,
          _1: param_1
        };
}

function splitWhen(str, predicate) {
  var _index = 0;
  while(true) {
    var index = _index;
    var $$char = str[index];
    if ($$char === undefined) {
      return [
              str,
              "",
              ""
            ];
    }
    if (predicate($$char)) {
      return [
              str.substring(0, index),
              str.substring(index, index + 1 | 0),
              str.substring(index + 1 | 0)
            ];
    }
    _index = index + 1 | 0;
    continue ;
  };
}

function pathFromString(str) {
  var parse = function (_str, _prevState, acc) {
    while(true) {
      var prevState = _prevState;
      var str = _str;
      var match = splitWhen(str, (function ($$char) {
              if ($$char === "[") {
                return true;
              } else {
                return $$char === ".";
              }
            }));
      if (match[0] === "" && match[1] === "" && match[2] === "") {
        return {
                TAG: "Ok",
                _0: acc
              };
      }
      if (prevState === "Name") {
        var name = match[0];
        switch (match[1]) {
          case "" :
              if (match[2] === "" && name !== "") {
                acc.push({
                      TAG: "Name",
                      _0: name
                    });
                return {
                        TAG: "Ok",
                        _0: acc
                      };
              } else {
                return {
                        TAG: "Error",
                        _0: "InvalidPath"
                      };
              }
          case "." :
              if (name === "") {
                return {
                        TAG: "Error",
                        _0: "InvalidPath"
                      };
              }
              acc.push({
                    TAG: "Name",
                    _0: name
                  });
              _prevState = "Name";
              _str = match[2];
              continue ;
          case "[" :
              if (name !== "") {
                acc.push({
                      TAG: "Name",
                      _0: name
                    });
                return parseIndex(match[2], acc);
              } else {
                return {
                        TAG: "Error",
                        _0: "InvalidPath"
                      };
              }
          default:
            return {
                    TAG: "Error",
                    _0: "InvalidPath"
                  };
        }
      } else {
        if (match[0] !== "") {
          return {
                  TAG: "Error",
                  _0: "InvalidPath"
                };
        }
        switch (match[1]) {
          case "." :
              _prevState = "Name";
              _str = match[2];
              continue ;
          case "[" :
              return parseIndex(match[2], acc);
          default:
            return {
                    TAG: "Error",
                    _0: "InvalidPath"
                  };
        }
      }
    };
  };
  var parseIndex = function (rest, acc) {
    var match = splitWhen(rest, (function ($$char) {
            return $$char === "]";
          }));
    var index = match[0];
    if (match[1] === "]" && index.search(/^[0-9]+$/) !== -1) {
      acc.push({
            TAG: "ListIndex",
            _0: parseInt(index) | 0
          });
      return parse(match[2], "Index", acc);
    } else {
      return {
              TAG: "Error",
              _0: {
                TAG: "InvalidIndex",
                _0: index
              }
            };
    }
  };
  var acc = [];
  var path = parse(str, "Name", acc);
  if (path.TAG !== "Ok") {
    return path;
  }
  var match = path._0.shift();
  if (match !== undefined) {
    if (match.TAG === "Name") {
      return {
              TAG: "Ok",
              _0: {
                TAG: "AttributePath",
                _0: {
                  TAG: "Name",
                  _0: match._0
                },
                _1: acc
              }
            };
    } else {
      return {
              TAG: "Error",
              _0: "MissingBaseNameBeforeIndex"
            };
    }
  } else {
    return {
            TAG: "Error",
            _0: "EmptyPath"
          };
  }
}

function throwError(message) { throw new Error(message); }
;

function pathFromStringUnsafe(path) {
  var path$1 = pathFromString(path);
  if (path$1.TAG === "Ok") {
    return path$1._0;
  } else {
    return throwError(JSON.stringify(path$1._0));
  }
}

function toString(x) {
  var nameToString = function (name) {
    if (name.includes(" ")) {
      throwError("InvalidName");
    }
    return "#" + name;
  };
  switch (x.TAG) {
    case "AttributePath" :
        return x._1.reduce((function (acc, sub) {
                      if (sub.TAG === "Name") {
                        return acc + "." + nameToString(sub._0);
                      } else {
                        return acc + "[" + String(sub._0) + "]";
                      }
                    }), nameToString(x._0._0));
    case "Name" :
        return nameToString(x._0);
    case "AttributeValue" :
        return ":" + x._0.alias;
    
  }
}

export {
  name ,
  attributeValue ,
  attributePath ,
  pathFromString ,
  pathFromStringUnsafe ,
  toString ,
}
/*  Not a pure module */
