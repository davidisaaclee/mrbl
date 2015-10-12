_ = require 'lodash'
InspectorBase = require './InspectorBase'

class RedInspector extends InspectorBase
  constructor: (@paper, @size, fetchState) ->
    @refs = {}
    super @paper, @size, fetchState

  update: (state) ->
    @refs.background.fillColor.brightness = state.backgroundLightness
    @refs.background.fillColor.hue = state.backgroundHue

    targetScrubberHeight =
      @refs.background.bounds.height * state.scrubberHeight
    @refs.scrubber.scale 1,
      targetScrubberHeight / @refs.scrubber.bounds.height
    @refs.scrubber.position.y =
      @refs.background.bounds.bottom - @refs.scrubber.bounds.height / 2

    @refs.playhead.position.x =
      @refs.background.bounds.width *
      state.playheadPosition +
      @refs.background.bounds.left

    {path, shadow} = @refs.entity
    path.rotation = state.entityRotation - path.data.rotationOrigin
    shadow.rotation = state.entityRotation - shadow.data.rotationOrigin
    state.entity.path.rotation = state.entityRotation
    state.entity.shadow.rotation = state.entityRotation

  # Make a new Paper.js representation of this inspector.
  draw: (state, paper, size) ->
    ratio = 1.77

    prettySize = new paper.Size size.width, size.width / ratio
    if prettySize.height > size.height
      prettySize = new paper.Size size.height * ratio, size.height

    topLeft = (new paper.Point prettySize).negate().multiply 0.5
    bounds = new paper.Rectangle topLeft, prettySize

    @refs.background = @_createBackground state, paper, bounds
    @refs.scrubber = @_createScrubber state, paper, bounds
    @refs.entityGroup = @_createEntity state, paper, bounds


    result = new paper.Group
      children: [ @refs.background
                  @refs.scrubber
                  @refs.entityGroup ]

    return result

  _createBackground: (state, paper, bounds) ->
    rect = new paper.Path.Rectangle
      name: 'redInspectorBG'
      size: bounds.size
      fillColor: new paper.Color
        hue: 0.62
        saturation: 0.81
        lightness: 0.2
    rect.position = [0, 0]

    rect.on 'mousedrag', (evt) =>
      evt.stopPropagation()
      evt.preventDefault()
      @dispatchEvent 'background.drag', evt

    # rect.on 'frame', () =>
    #   rect.fillColor.hue = (@getFeedbackParameter 'hue') * 360
    #   rect.fillColor.lightness = (@getFeedbackParameter 'lightness')
    #   paper.view.draw()

    return rect

  _createScrubber: (state, paper, bounds) ->
    scrubberGroup = new paper.Group()

    scrubber = new paper.Path.Rectangle
      point: bounds.topLeft
      size: [bounds.width, bounds.height]
    scrubberGroup.addChild scrubber

    scrubber.fillColor = 'black'
    scrubber.opacity = 0.2
    scrubber.name = 'scrubber'

    @refs.playhead = new paper.Path.Rectangle
      point: scrubber.bounds.topLeft
      size: [1, scrubber.bounds.height]
      fillColor: 'white'
      name: 'playhead'
      opacity: 1
    scrubberGroup.addChild @refs.playhead

    scrubber.on 'mousedrag', (evt) =>
      evt.stopPropagation()
      evt.preventDefault()
      @dispatchEvent 'scrubber.drag', evt

    return scrubberGroup

  _createEntity: (state, paper, bounds) ->
    result = new paper.Group()

    original = state.entity.path
    originalShadow = state.entity.shadow

    copy = state.entity.path.clone()
    shadowCopy = state.entity.shadow.clone()

    copy.data.rotationOrigin = original.rotation
    shadowCopy.data.rotationOrigin = originalShadow.rotation

    copy.strokeColor = null

    delta = copy.position.negate()
    copy.translate delta
    shadowCopy.translate delta

    result.addChild shadowCopy
    result.addChild copy

    result.transformChildren = false

    result.fitBounds bounds
    result.scale 0.5, 0.5

    @refs.entity =
      path: copy
      shadow: shadowCopy

    return result

module.exports = RedInspector