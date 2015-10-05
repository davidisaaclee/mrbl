module.exports = cameraControlTool = (paper, tool, canvas, onTransform) ->
  if not onTransform?
    onTransform = ->


  zoom = (amount, pt) ->
    scrollAmount = paper.view.center.subtract pt

    if paper.view.zoom > 5 and amount > 1
      return
    if paper.view.zoom < 0.5 and amount < 1
      return

    paper.view.scrollBy scrollAmount
    paper.view.zoom *= amount
    paper.view.scrollBy scrollAmount.negate().multiply amount
    do onTransform

  canvas.addEventListener 'mousewheel', (evt) ->
    evt.stopPropagation()
    evt.preventDefault()

    if not paper.Key.isDown 'option'
      mouseOffset = new paper.Point evt.offsetX, evt.offsetY
      projMouseOffset = paper.view.viewToProject mouseOffset

      delta = evt.deltaY / 100.0
      delta *= 0.8
      zoom (1 + delta), projMouseOffset

  setupPan paper, tool, canvas, onTransform


setupPan = (paper, tool, canvas, onTransform) ->
  panInertia = new paper.Point 0, 0
  lastScroll = new paper.Point 0, 0

  # is this silly?
  lastPoint = null
  mouseButtonDown = false
  LEFT_MOUSE = 0

  tool.on 'mousedown', (evt) ->
    # ToolEvent.point gives us the point in project coordinates
    lastPoint = paper.view.projectToView evt.point
    if evt.event.button is LEFT_MOUSE
      mouseButtonDown = true
  tool.on 'mouseup', (evt) ->
    if evt.event.button is LEFT_MOUSE
      mouseButtonDown = false

  canvas.addEventListener 'mousemove', (evt) ->
    if mouseButtonDown
      pt = new paper.Point evt.offsetX, evt.offsetY
      viewDelta = lastPoint.subtract pt
      panInertia = viewDelta.multiply (1 / paper.view.zoom)
      lastPoint = pt

  tool.on 'mousedown', (evt) ->
    panInertia = new paper.Point 0, 0

  window.addEventListener 'focus', () ->
    panInertia = new paper.Point 0, 0

  canvas.addEventListener 'mousewheel', (evt) ->
    evt.stopPropagation()
    evt.preventDefault()
    if paper.Key.isDown 'option'
      delta = new paper.Point evt.deltaX, evt.deltaY
      delta = delta.multiply (1 / paper.view.zoom)
      panInertia = delta

  # tool.on 'mousedrag', (evt) ->
  #   # TODO: this is getting triggered too much man

  #   if paper.Key.isDown 'option'
  #     mouseOffset = new paper.Point evt.offsetX, evt.offsetY
  #     projMouseOffset = paper.view.viewToProject mouseOffset
  #     zoom 1 + 2 * evt.delta.x / paper.view.size.width, paper.view.center
  #   else
  #     lastPointAdjust = evt.lastPoint.add lastScroll
  #     scrollAmount = lastPointAdjust.subtract evt.point
  #     panInertia = panInertia.add scrollAmount.multiply 0.4

  paper.view.on 'frame', (evt) ->
    if panInertia.length > 0.01
      paper.view.center = paper.view.center.add panInertia
      if not paper.Key.isDown 'option'
        panInertia = panInertia.multiply (58 * evt.delta)
      do onTransform