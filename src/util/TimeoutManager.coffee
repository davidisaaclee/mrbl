class TimeoutManager
  constructor: () ->
    @_clearSet = {}

  setTimeout: (delay, proc) ->
    timeoutId = null

    procAndRemove = () =>
      do proc
      delete @_clearSet["#{timeoutId}"]

    timeoutId = setTimeout procAndRemove, delay

    @_clearSet["#{timeoutId}"] = () =>
      clearTimeout timeoutId
      delete @_clearSet["#{timeoutId}"]

  clearAll: () ->
    for k, v of @_clearSet
      do v
    @_clearSet = {}


module.exports = TimeoutManager