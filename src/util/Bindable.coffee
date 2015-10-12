_ = require 'lodash'

class Bindable
  constructor: (@fetchState) ->
    @created()
    state = @fetchState()
    @loaded state
    @update state
    @ready state

  # Called before grabbing state and before updating for the first time.
  created: () -> # override me!

  # Called after grabbing state but before updating for the first time.
  loaded: () -> # override me!

  # Called after grabbing state and after updating for the first time.
  ready: (state) -> # override me!

  # Call to update based on latest state.
  dirty: () -> @update @fetchState()

  # Configure self according to state.
  update: (state) -> # override me!

module.exports = Bindable