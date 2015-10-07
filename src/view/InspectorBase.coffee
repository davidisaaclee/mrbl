{EventEmitter} = require 'events'

###
Abstract class for inspectors.
###
class InspectorBase extends EventEmitter
  constructor: (parameterCallbacks = {}, feedbackGetters = {}) ->
    @_parameterCallbacks = parameterCallbacks
    @_feedbackGetters = feedbackGetters


  ## Drawing

  draw: (paper, size) ->
    console.warn 'Inspector needs to override `draw()`.'

  remove: () ->
    console.warn 'Inspector needs to override `remove()`.'    

  ## Parameters

  parameterList: () ->
    console.warn 'Inspector needs to override `parameterList()`.'

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


  ## Visual feedback

  feedbackList: () ->
    console.warn 'Inspector needs to override `feedbackList()`.'

  mapFeedbackParameter: (paramName, getFn) ->
    @_feedbackGetters[paramName] = getFn

  getFeedbackParameter: (paramName) ->
    if @_feedbackGetters[paramName]?
    then @_feedbackGetters[paramName]()
    else undefined

  # used internally to link a feedback parameter to a view
  _addFeedbackListener: (paramName, callback) ->
    # TODO

  _removeFeedbackListener: (paramName, callback) ->
    # TODO

module.exports = InspectorBase