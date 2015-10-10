_ = require 'lodash'

class Parameter
  constructor: (@name, defaultValue = 0) ->
    @value = defaultValue
    @_lastValue = defaultValue

    callbackCount = 0
    @_nextCallbackId = () -> "cb-#{callbackCount++}"

  subscribe: (callback, options) ->
    options = _.defaults options,
      # should this callback be invoked immediately with the most recent value?
      shouldPrime: false
      # a function to transform the value before sending to callback
      transform: _.identity

    id = @_nextCallbackId()
    transformedCallback = (v, delta) ->
      callback (options.transform v), delta
    @_callbacks[id] = transformedCallback

    if options.shouldPrime
      transformedCallback @value, 0

    return () => delete @_callbacks[id]

  ###
  @param value [Number] The raw new value for this parameter.
  ###
  set: (@value) ->
    @_notifyChanged @value

  ###
  ###
  get: () ->
    return @value

  _notifyChanged: (value) ->
    delta = value - @_lastValue

    for k, cb of @_callbacks
      cb value, delta

    @_lastValue = value


module.exports = Parameter