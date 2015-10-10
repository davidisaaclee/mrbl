InspectorBase = require './InspectorBase'

class RedInspector extends InspectorBase
  constructor: (@entity, parameterCallbacks) ->
    super parameterCallbacks

    # holds all results of calling `draw()`
    @_gfxInstances = []

  parameterList: () ->
    return [ 'backgroundX'
             'backgroundY'
             'scrubberX'
             'scrubberY' ]

  feedbackParameterList: () -> [ 'scrubberHeight' ]

  # Make a new Paper.js representation of this inspector.
  draw: (paper, size) ->
    ratio = 1.77

    prettySize = new paper.Size size.width, size.height / ratio
    if prettySize.height > size.height
      prettySize = new paper.Size size.height * ratio, size.height

    topLeft = (new paper.Point prettySize).negate().multiply 0.5
    bounds = new paper.Rectangle topLeft, prettySize

    result = new paper.Group
      children: [ @_createBackground paper, bounds, @entity
                  @_createScrubber paper, bounds, @entity
                  @_createEntity paper, bounds, @entity ]

    @_setupInteraction paper, result

    @_gfxInstances.push result

    @refreshFeedbackParameters()

    return result

  # Remove all Paper.js representations from their respective projects.
  remove: () ->
    @_gfxInstances.forEach (inst) -> inst.remove()
    @_gfxInstances = []

    @_destroyInteraction()
    @_removeAllFeedbackListeners()


  defaultFeedbackValues: () ->
    'scrubberHeight': 0.2
    'playheadPosition': 0.5
    'itemAgitation': 0.5
    'hue': 0
    'lightness': 0.62



  _createBackground: (paper, bounds, entity) ->
    rect = new paper.Path.Rectangle
      name: 'redInspectorBG'
      size: bounds.size
      fillColor: new paper.Color
        hue: @getFeedbackParameter 'hue'
        saturation: 0.81
        lightness: @getFeedbackParameter 'lightness'
    rect.position = [0, 0]

    rect.data.onMousewheel = (evt) =>
      evt.stopPropagation()
      evt.preventDefault()

      nudgeAmountX = -evt.deltaX / 100
      oldValueX = @getParameter 'backgroundX'
      @setParameter 'backgroundX', oldValueX + nudgeAmountX

      nudgeAmountY = evt.deltaY / 100
      oldValueY = @getParameter 'backgroundY'
      @setParameter 'backgroundY', oldValueY + nudgeAmountY

    rect.on 'frame', () =>
      rect.fillColor.hue = (@getFeedbackParameter 'hue') * 360
      rect.fillColor.lightness = (@getFeedbackParameter 'lightness')
      paper.view.draw()

    return rect

  _createScrubber: (paper, bounds, entity) ->
    scrubberGroup = new paper.Group()

    scrubber = new paper.Path.Rectangle
      point: bounds.topLeft
      size: [bounds.width, bounds.height]
    scrubberGroup.addChild scrubber

    scrubber.fillColor = 'black'
    scrubber.opacity = 0.2
    scrubber.name = 'scrubber'

    playhead = new paper.Path.Rectangle
      point: scrubber.bounds.topLeft
      size: [1, scrubber.bounds.height]
      fillColor: 'white'
      name: 'playhead'
      opacity: 0
    scrubberGroup.addChild playhead

    initialHeight = scrubber.bounds.size.height * 0.8
    @_addFeedbackListener 'scrubberHeight', (val, delta) ->
      cooked = val * 0.8 + 0.2
      targetHeight = cooked * initialHeight
      scaleRatio = targetHeight / scrubber.bounds.size.height
      scrubber.scale 1, scaleRatio

      paper.view.draw()

      distanceToBottom = scrubber.parent.parent.bounds.bottom - scrubber.bounds.bottom
      scrubber.translate [0, distanceToBottom]

      paper.view.draw()


    onPlayheadPosition = (val, delta) ->
      playhead.position.x = scrubber.bounds.left + val * scrubber.bounds.width
      playhead.opacity = 0.2
      paper.view.draw()

    afterPlayheadPosition = (val) ->
      playhead.opacity = 0
      paper.view.element.style.cursor = 'default'
      paper.view.draw()

    @_addFeedbackListener 'playheadPosition', onPlayheadPosition, afterPlayheadPosition

    delta = new paper.Point 0, 0
    scrubber.on 'frame', () ->
      scrubber.translate delta.negate()
      range = 2
      delta = new paper.Point \
        Math.random() * range - (range / 2),
        Math.random() * range - (range / 2)
      scrubber.translate delta


    scrubber.data.onMousewheel = (evt) =>
      evt.stopPropagation()
      evt.preventDefault()

      nudgeAmountX = -evt.deltaX / 100
      oldValueX = @getParameter 'scrubberX'
      @setParameter 'scrubberX', oldValueX + nudgeAmountX

      nudgeAmountY = evt.deltaY / 100
      oldValueY = @getParameter 'scrubberY'
      @setParameter 'scrubberY', oldValueY + nudgeAmountY


    return scrubberGroup

  _createEntity: (paper, bounds, entity) ->
    result = new paper.Group()

    original = entity.paper.path
    originalShadow = entity.paper.shadow

    copy = entity.paper.path.clone()
    copy.strokeColor = null
    shadowCopy = entity.paper.shadow.clone()

    delta = copy.position.negate()
    copy.translate delta
    shadowCopy.translate delta

    result.addChild shadowCopy
    result.addChild copy


    # agitation = 0
    # @_addFeedbackListener 'itemAgitation', (v) -> agitation = v * 50
    # result.on 'frame', (evt) ->
    #   # result.rotate evt.delta * agitation
    #   original.segments.forEach (originalSegment, idx) ->
    #     randomPoint = new paper.Point (Math.random() - 0.5),
    #                                   (Math.random() - 0.5)
    #     agitationAmount = randomPoint.multiply agitation

    #     copy.segments[idx].point =
    #       originalSegment.point.add agitationAmount
    #     shadowCopy.segments[idx].point =
    #       originalShadow.segments[idx].point.add agitationAmount

    return result

  _setupInteraction: (paper, group) ->
    onMousewheel = @_onMousewheel paper, group
    paper.view.element.addEventListener 'mousewheel', onMousewheel
    @_destroyInteraction = () ->
      paper.view.element.removeEventListener 'mousewheel', onMousewheel

  _onMousewheel: (paper, group) => (evt) =>
    pt = paper.view.viewToProject [evt.offsetX, evt.offsetY]
    hitResults = group.hitTest pt
    if hitResults?
      if hitResults.item.data.onMousewheel?
        hitResults.item.data.onMousewheel evt

module.exports = RedInspector