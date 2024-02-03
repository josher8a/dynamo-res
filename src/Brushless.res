// TODO: Move to external binding
// @genType
// module DefaultMarshaller = {
//   @genType.import(("@aws/dynamodb-auto-marshaller", "Marshaller"))
//   type t
//   %%private(
//     @new @module("@aws/dynamodb-auto-marshaller") external init: unit => t = "Marshaller"
//     @send @genType
//     external marshallValue: (t, 'a) => marshalledValue = "marshallValue"
//   )
//   let marshaller = init()
//   let marshallValue = x => marshallValue(marshaller, x)
// }

@genType
module Register = {
  type t = {
    names: Dict.t<string>,
    values: Dict.t<Attribute.marshalledValue>,
  }

  let make = () => {names: Dict.make(), values: Dict.make()}

  let add = (register, element: Attribute.t) => {
    open Attribute
    switch element {
    | Name(name) => register.names->Dict.set(element->toString, name)

    | AttributeValue({value}) => register.values->Dict.set(element->toString, value)

    | AttributePath(base, subpath) =>
      [(base :> Attribute.sub)]
      ->Array.concat(subpath)
      ->Array.forEach(sub =>
        switch sub {
        | Name(name) => register.names->Dict.set(Name(name)->toString, name)
        | ListIndex(_) => ()
        }
      )
    }
    element
  }

  let addToString = (register, element: Attribute.t) => {
    add(register, element)->Attribute.toString
  }
}

@genType
module Condition = {
  @genType @deriving(accessors)
  type size = Size(Attribute.t) // is a function but it is the only one that returns a number

  type operand = | ...Attribute.t | ...size

  type limits = {lower: operand, upper: operand}

  @genType @deriving(accessors)
  type rec condition =
    | Equals(operand, operand)
    | NotEquals(operand, operand)
    | LessThan(operand, operand)
    | LessThanOrEqual(operand, operand)
    | GreaterThan(operand, operand)
    | GreaterThanOrEqual(operand, operand)
    | Between(operand, limits)
    | InList(operand, array<operand>)
    | And(condition, condition)
    | Or(condition, condition)
    | Not(condition)
    | AttributeExists(Attribute.identifier)
    | AttributeNotExists(Attribute.identifier)
    | AttributeType(Attribute.identifier, operand)
    | BeginsWith(Attribute.identifier, operand)
    | Contains(Attribute.identifier, operand)

  module Overload = {
    @genType.opaque
    let \"&&" = \"and"
    @genType.opaque
    let \"||" = or
    @genType.opaque
    let \"!" = not
    @genType.opaque
    let \"==" = equals
    @genType.opaque
    let \"!=" = notEquals
    @genType.opaque
    let \"<" = lessThan
    @genType.opaque
    let \"<=" = lessThanOrEqual
    @genType.opaque
    let \">" = greaterThan
    @genType.opaque
    let \">=" = greaterThanOrEqual
  }

  let build = (condition, register) => {
    let rec toString = condition =>
      switch condition {
      | Equals(lhs, rhs) => `${opString(lhs)} = ${opString(rhs)}`
      | NotEquals(lhs, rhs) => `${opString(lhs)} <> ${opString(rhs)}`
      | LessThan(lhs, rhs) => `${opString(lhs)} < ${opString(rhs)}`
      | LessThanOrEqual(lhs, rhs) => `${opString(lhs)} <= ${opString(rhs)}`
      | GreaterThan(lhs, rhs) => `${opString(lhs)} > ${opString(rhs)}`
      | GreaterThanOrEqual(lhs, rhs) => `${opString(lhs)} >= ${opString(rhs)}`
      | Between(operand, limits) =>
        `${opString(operand)} BETWEEN ${opString(limits.lower)} AND ${opString(limits.upper)}`
      | InList(operand, list) =>
        `${opString(operand)} IN (${list->Array.map(opString)->Array.joinWith(", ")})`
      | And(lhs, rhs) => `(${toString(lhs)}) AND (${toString(rhs)})`
      | Or(lhs, rhs) => `(${toString(lhs)}) OR (${toString(rhs)})`
      | Not(condition) => `NOT (${toString(condition)})`
      | AttributeExists(identifier) => `attribute_exists(${opString((identifier :> operand))}})`
      | AttributeNotExists(identifier) =>
        `attribute_not_exists(${opString((identifier :> operand))}})`
      | AttributeType(identifier, operand) =>
        `attribute_type(${opString((identifier :> operand))}}, ${opString(operand)})`
      | BeginsWith(identifier, operand) =>
        `begins_with(${opString((identifier :> operand))}}, ${opString(operand)})`
      | Contains(identifier, operand) =>
        `contains(${opString((identifier :> operand))}}, ${opString(operand)})`
      }
    and opString = operand =>
      switch operand {
      | AttributePath(base, subPath) => Register.addToString(register, AttributePath(base, subPath))
      | Name(name) => Register.addToString(register, Name(name))
      | AttributeValue(x) => Register.addToString(register, AttributeValue(x))
      | Size(operand) => `size(${opString((operand :> operand))}})`
      }

    toString(condition)
  }
}

@genType
module Projection = {
  type projection = array<Attribute.identifier>

  let build = (projection: projection, register) =>
    projection
    ->Array.map(x => Register.addToString(register, (x :> Attribute.t)))
    ->Array.joinWith(", ")
}

@genType
module KeyCondition = {
  @genType @deriving(accessors)
  type pkCondition = PartitionKey(Attribute.name, Attribute.value)
  type limits = {lower: Attribute.value, upper: Attribute.value}
  @genType @deriving(accessors)
  type skCondition =
    | Equals(Attribute.name, Attribute.value)
    | NotEquals(Attribute.name, Attribute.value)
    | LessThan(Attribute.name, Attribute.value)
    | LessThanOrEqual(Attribute.name, Attribute.value)
    | GreaterThan(Attribute.name, Attribute.value)
    | GreaterThanOrEqual(Attribute.name, Attribute.value)
    | Between(Attribute.name, limits)
    | BeginsWith(Attribute.name, Attribute.value)

  type keyCondition = {
    pk: pkCondition,
    sk?: skCondition,
  }

  %%private(
    let skConditionToString = (skCondition: skCondition, register) =>
      switch skCondition {
      | Equals(name, value) =>
        ` AND ${Register.addToString(register, (name :> Attribute.t))} = ${Register.addToString(
            register,
            (value :> Attribute.t),
          )}`
      | NotEquals(name, value) =>
        ` AND ${Register.addToString(register, (name :> Attribute.t))} <> ${Register.addToString(
            register,
            (value :> Attribute.t),
          )}`
      | LessThan(name, value) =>
        ` AND ${Register.addToString(register, (name :> Attribute.t))} < ${Register.addToString(
            register,
            (value :> Attribute.t),
          )}`
      | LessThanOrEqual(name, value) =>
        ` AND ${Register.addToString(register, (name :> Attribute.t))} <= ${Register.addToString(
            register,
            (value :> Attribute.t),
          )}`
      | GreaterThan(name, value) =>
        ` AND ${Register.addToString(register, (name :> Attribute.t))} > ${Register.addToString(
            register,
            (value :> Attribute.t),
          )}`
      | GreaterThanOrEqual(name, value) =>
        ` AND ${Register.addToString(register, (name :> Attribute.t))} >= ${Register.addToString(
            register,
            (value :> Attribute.t),
          )}`
      | Between(name, limits) =>
        ` AND ${Register.addToString(
            register,
            (name :> Attribute.t),
          )} BETWEEN ${Register.addToString(
            register,
            (limits.lower :> Attribute.t),
          )} AND ${Register.addToString(register, (limits.upper :> Attribute.t))}`
      | BeginsWith(name, value) =>
        ` AND begins_with(${Register.addToString(
            register,
            (name :> Attribute.t),
          )}, ${Register.addToString(register, (value :> Attribute.t))})`
      }

    let pkConditionToString = (PartitionKey(name, value), register) =>
      `${Register.addToString(register, (name :> Attribute.t))} = ${Register.addToString(
          register,
          (value :> Attribute.t),
        )}`
  )

  let build = (condition: keyCondition, register) =>
    pkConditionToString(condition.pk, register) ++
    switch condition.sk {
    | Some(skCondition) => skConditionToString(skCondition, register)
    | None => ""
    }
}

@genType
module Update = {
  type funcParams<'a> = {
    identifier: 'a,
    operand: 'a,
  }
  @genType @deriving(accessors)
  type rec operand =
    | Attribute(Attribute.t)
    | ListAppend(funcParams<operand>)
    | IfNotExists(funcParams<operand>)
    | Sum(operand, operand)
    | Sub(operand, operand)

  type rec update = {
    set?: array<(Attribute.identifier, operand)>,
    remove?: array<Attribute.identifier>,
    add?: array<(Attribute.identifier, Attribute.t)>,
    delete?: array<(Attribute.identifier, Attribute.t)>,
  }

  %%private(
    let rec operandToString = (operand: operand, register) =>
      switch operand {
      | Attribute(attr) => Register.addToString(register, attr)
      | ListAppend({identifier, operand}) =>
        `list_append(${operandToString(identifier, register)}, ${operandToString(
            operand,
            register,
          )})`
      | IfNotExists({identifier, operand}) =>
        `if_not_exists(${operandToString(identifier, register)}, ${operandToString(
            operand,
            register,
          )})`
      | Sum(lhs, rhs) => `${operandToString(lhs, register)} + ${operandToString(rhs, register)}`
      | Sub(lhs, rhs) => `${operandToString(lhs, register)} - ${operandToString(rhs, register)}`
      }
    let appendIfNotEmpty = (acc, arr, tag, fn) => {
      open Array
      switch arr {
      | Some(x) if x->length > 0 => acc ++ tag ++ " " ++ x->map(fn)->joinWith(", ") ++ " "
      | _ => acc
      }
    }
  )

  let build = (update: update, register) => {
    let toString = attr => Register.addToString(register, attr)
    ""
    ->appendIfNotEmpty(update.add, "ADD", ((id, value)) =>
      toString((id :> Attribute.t)) ++ " " ++ toString((value :> Attribute.t))
    )
    ->appendIfNotEmpty(update.delete, "DELETE", ((id, value)) =>
      toString((id :> Attribute.t)) ++ " " ++ toString((value :> Attribute.t))
    )
    ->appendIfNotEmpty(update.set, "SET", ((id, operand)) =>
      toString((id :> Attribute.t)) ++ " = " ++ operandToString(operand, register)
    )
    ->appendIfNotEmpty(update.remove, "REMOVE", x => toString((x :> Attribute.t)))
    ->String.trim
  }
}
// TODO: Move to external binding in TS/JS
// @genType
// module U = {
//   include Update
// }
// @genType
// module C = {
//   include Condition
// }
// @genType
// module K = {
//   include KeyCondition
// }
// @genType
// module P = {
//   include Projection
// }
