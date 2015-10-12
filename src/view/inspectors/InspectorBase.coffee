_ = require 'lodash'
EventTarget = require 'oo-eventtarget'

Bindable = require '../../util/Bindable'

###
Abstract class for inspectors.
###
class InspectorBase extends Bindable
  constructor: (@paper, @size, fetchState) ->
    super fetchState
    EventTarget this

  loaded: (state) ->
    @paperItem = @draw state, @paper, @size
    @paper.view.draw()


  ## Drawing

  draw: (paper, size) ->
    console.warn 'Inspector needs to override `draw()`.'

  remove: () -> @paperItem.remove()


  ## Parameters

  # Something's changed; fetch new state, update.
  dirty: () -> @update @fetchState()

  # Perform any updates according to new state.
  update: (state) -> # override me!


module.exports = InspectorBase