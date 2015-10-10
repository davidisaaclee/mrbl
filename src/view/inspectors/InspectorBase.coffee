{EventEmitter} = require 'events'
_ = require 'lodash'

###
Abstract class for inspectors.
###
class InspectorBase extends EventEmitter
  constructor: (parameterCallbacks = {}) ->
    @_parameterCallbacks = parameterCallbacks
    @_feedbackParameters = _.mapValues @defaultFeedbackValues(), (value, key) ->
      callbacks: []
      value: value


  ## Drawing

  draw: (paper, size) ->

  remove: () ->

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

  # Define default values for feedback parameters.
  # @returns {<paramName>: <value : Float>}
  defaultFeedbackValues: () ->
    console.warn 'Inspector needs to override `defaultFeedbackValues()`.'
    {}


  refreshFeedbackParameters: () ->
    Object.keys @_feedbackParameters
      .forEach (paramName) =>
        @setFeedbackParameter paramName, @_feedbackParameters[paramName].value

  # Updates the specified parameter. Triggers all feedback listeners on that
  #   parameter.
  setFeedbackParameter : (paramName, value) ->
    delta = value - @_feedbackParameters[paramName].value
    @_feedbackParameters[paramName].value = value
    @emit "#{paramName}ChangedFeedback", value, delta

  getFeedbackParameter: (paramName) ->
    @_feedbackParameters[paramName].value

  # used internally to link a feedback parameter to a view
  _addFeedbackListener: (paramName, callback, afterInteractionCallback) ->
    afterInteractionCallbackId = null

    @on "#{paramName}ChangedFeedback", () ->
      args = arguments
      if afterInteractionCallback?
        if afterInteractionCallbackId?
          clearTimeout afterInteractionCallbackId
          afterInteractionCallbackId = null
        afterInteractionCallbackId =
          setTimeout (() -> afterInteractionCallback args...), 100
      callback args...
    # TODO: make sure these don't leak
    @_feedbackParameters[paramName].callbacks.push callback

  _removeFeedbackListener: (paramName, callback) ->
    @removeListener "#{paramName}ChangedFeedback", callback

  _removeAllFeedbackListeners: () ->
    (Object.keys @_feedbackParameters).forEach (paramName) =>
      @_feedbackParameters[paramName].callbacks.forEach (callback) =>
        @_removeFeedbackListener paramName, callback



module.exports = InspectorBase