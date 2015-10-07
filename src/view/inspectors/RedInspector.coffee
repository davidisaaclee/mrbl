InspectorBase = require '../InspectorBase'

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

  # Make a new Paper.js representation of this inspector.
  draw: (paper, size) ->
    topLeft = (new paper.Point size).negate().multiply 0.5
    bounds = new paper.Rectangle topLeft, size

    result = new paper.Group
      children: [ @_createBackground paper, bounds, @entity
                  @_createScrubber paper, bounds, @entity
                  @_createEntity paper, bounds, @entity ]

    @_setupInteraction paper, result

    @_gfxInstances.push result
    return result

  # Remove all Paper.js representations from their respective projects.
  remove: () ->
    @_gfxInstances.forEach (inst) -> inst.remove()
    @_gfxInstances = []

    @_destroyInteraction()


  _createBackground: (paper, bounds, entity) ->
    rect = new paper.Path.Rectangle
      size: bounds.size
      fillColor: 'red'
    rect.position = [0, 0]

    rect.data.onMousewheel = (evt) =>
      evt.stopPropagation()
      evt.preventDefault()

      nudgeAmountX = evt.deltaX / 100
      oldValueX = @getParameter 'backgroundX'
      @setParameter 'backgroundX', oldValueX + nudgeAmountX

      nudgeAmountY = evt.deltaY / 100
      oldValueY = @getParameter 'backgroundY'
      @setParameter 'backgroundY', oldValueY + nudgeAmountY

    return rect

  _createScrubber: (paper, bounds, entity) ->
    scrubber = new paper.Path.Rectangle
      point: bounds.bottomLeft.subtract [0, bounds.height * 0.1]
      size: [bounds.width, bounds.height * 0.1]
    scrubber.fillColor = 'black'
    scrubber.opacity = 0.2
    scrubber.name = 'scrubber'

    scrubber.data.onMousewheel = (evt) =>
      evt.stopPropagation()
      evt.preventDefault()

      nudgeAmountX = evt.deltaX / 100
      oldValueX = @getParameter 'scrubberX'
      @setParameter 'scrubberX', oldValueX + nudgeAmountX

      nudgeAmountY = evt.deltaY / 100
      oldValueY = @getParameter 'scrubberY'
      @setParameter 'scrubberY', oldValueY + nudgeAmountY

    return scrubber

  _createEntity: (paper, bounds, entity) ->
    result = new paper.Group()

    copy = entity.paper.path.clone()
    copy.strokeColor = null
    shadowCopy = entity.paper.shadow.clone()

    delta = copy.position.negate()
    copy.translate delta
    shadowCopy.translate delta

    result.addChild shadowCopy
    result.addChild copy

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