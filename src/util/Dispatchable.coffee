module.exports = mixinDispatchable = (onObj, dispatcher) ->
  onObj.dispatch = (actionType, data) ->
    dispatcher.dispatch
      action:
        actionType: actionType
        data: data
  return onObj