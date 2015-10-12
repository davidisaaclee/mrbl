_ = require 'lodash'

###
A `Transformer` provides a simplified interface to other modules via named
  parameters.
###
class Transformer
  constructor: () ->
    @_parameters = {}

  ###
  Calls the named parameter's getter function.

  @param name [String] The relevant parameter's name.
  @returns The result of calling the parameter's getter function with the latest
    local value.
  ###
  get: (name) ->
    p = @_parameters[name]

    if p?
    then p.get p.local
    else undefined


  ###
  Calls the named parameter's setter function with the provided value.

  @param name [String] The relevant parameter's name.
  @param value [a] A value to be provided to the parameter's setter function.
  @returns [b] The result value of calling the parameter's setter function; or,
    if no such parameter, `undefined`.
  ###
  set: (name, value) ->
    p = @_parameters[name]

    if p?
    then p.local = p.set value
    else undefined


  ###
  Internal; registers a named parameter with setter and getter functions.
  Note: `setFn` and `getFn` are not necessarily symmetrical. That is,
      a = setFn x
      y = getFn a
      does not imply x == y

  @param name [String] The relevant parameter's name.
  @param options [Object] An object with a setter, getter, and default value:
    set [Function<a, b>] Performs any set subprocedures, and optionally
      returns a value to set as the "local value," to be provided to the getter.
    get [Function<b, c>] Gets a value for this parameter, provided a
      "local value" (which may be undefined if `setFn` does not return a value).
    default [b] The default value for this parameter.
  ###
  _registerParameter: (name, options) ->
    options = _.defaults options,
      set: (value) -> value
      get: (local) -> local
      default: undefined

    @_parameters[name] =
      local: options.default
      set: options.set
      get: options.get



module.exports = Transformer