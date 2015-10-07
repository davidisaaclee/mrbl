{EventEmitter} = require 'events'

###
Abstract class for inspectors.
###
class InspectorBase extends EventEmitter
  constructor: (parameterCallbacks = {}) ->
    @_parameterCallbacks = parameterCallbacks
    @_listeners = {}

  parameterList: () ->
    console.warn 'Inspector needs to override `parameterList()`.'

  draw: (paper, size) ->
    console.warn 'Inspector needs to override `draw()`.'

  mapParameter: (paramName, getFn, setFn) ->
    @_parameterCallbacks[paramName] =
      getFn: getFn
      setFn: setFn

  getParameter: (paramName) ->
    callbacks = @_parameterCallbacks[paramName]

    if callbacks?.getFn?
    then callbacks.getFn()
    else undefined

  setParameter: (paramName, value) ->
    callbacks = @_parameterCallbacks[paramName]

    if callbacks?.setFn?
      callbacks.setFn value
      @emit "#{paramName}Changed", value
    else undefined

  addParameterListener: (paramName, callback) ->
    @on "#{paramName}Changed", callback

  removeParameterListener: (paramName, callback) ->
    @removeListener "#{paramName}Changed", callback

module.exports = InspectorBase