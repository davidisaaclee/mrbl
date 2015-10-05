_ = require 'lodash'

{EventEmitter} = require 'events'
dispatcher = require '../Dispatcher'
Dispatchable = require '../util/Dispatchable'

CHANGE_EVENT = 'change'

class Store extends EventEmitter
  constructor: (initialData = {}) ->
    Dispatchable this, dispatcher
    @data = _.extend @getDefaultData(), initialData
    @registerOnDispatcher()

  getDefaultData: () -> {}

  getAll: () -> @data

  emitChange: () -> @emit CHANGE_EVENT

  addChangeListener: (cb) ->
    @on CHANGE_EVENT, cb

  removeChangeListener: (cb) ->
    @removeListener CHANGE_EVENT, cb

  delegate: undefined

  registerOnDispatcher: (delegate) ->
    if @delegate?
      dispatcher.register () => @delegate arguments...
    else
      console.warn 'No delegate for ', this

module.exports = Store