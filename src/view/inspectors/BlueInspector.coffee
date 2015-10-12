_ = require 'lodash'
EventTarget = require 'oo-eventtarget'
InspectorBase = require './InspectorBase'

class BlueInspector extends InspectorBase
  constructor: (@paper, @size, fetchState) ->
    @refs = {}
    super @paper, @size, fetchState
    EventTarget this
    console.log this

  draw: (state, paper, size) ->
    rect = new paper.Path.Rectangle [50, 50], [500, 500]
    rect.fillColor = 'blue'

    _.assign @refs, 'rect': rect

    rect.on 'mousedrag', (evt) => @dispatchEvent 'dragRect', evt

    return rect

  update: (state) ->
    @refs.rect.fillColor.brightness = state.foo / 100

module.exports = BlueInspector