
kLeftMouseFlag = 1

module.exports = cameraControlTool = (paper, tool, canvas, onTransform) ->
  if not onTransform?
    onTransform = ->

  setupZoom paper, tool, canvas, onTransform
  setupPan paper, tool, canvas, onTransform

setupZoom = (paper, tool, canvas, onTransform) ->
  zoom = (amount, pt) ->
    scrollAmount = paper.view.center.subtract pt

    newZoom = paper.view.zoom * amount
    newZoom = Math.max (Math.min newZoom, 5), 0.5

    if newZoom != paper.view.zoom
      paper.view.scrollBy scrollAmount
      paper.view.zoom = newZoom
      paper.view.scrollBy scrollAmount.negate().multiply amount
      do onTransform

  canvas.addEventListener 'mousewheel', (evt) ->
    evt.stopPropagation()
    evt.preventDefault()

    if not paper.Key.isDown 'option'
      mouseOffset = new paper.Point evt.offsetX, evt.offsetY
      projMouseOffset = paper.view.viewToProject mouseOffset

      delta = -evt.deltaY / 100.0
      delta *= 0.8
      zoom (1 + delta), projMouseOffset

  lastX = null
  canvas.addEventListener 'mousedown', (evt) ->
    lastX = evt.clientX

  canvas.addEventListener 'mousemove', (evt) ->
    mouseButtonDown = (evt.buttons & kLeftMouseFlag) is 1
    if mouseButtonDown and paper.Key.isDown 'option'
      mouseOffset = new paper.Point evt.offsetX, evt.offsetY
      projMouseOffset = paper.view.viewToProject mouseOffset

      deltaX = evt.clientX - lastX
      lastX = evt.clientX

      zoom 1 + 2 * deltaX / paper.view.viewSize.width, paper.view.center


setupPan = (paper, tool, canvas, onTransform) ->
  panInertia = new paper.Point 0, 0
  lastScroll = new paper.Point 0, 0

  # is this silly?
  lastPoint = null

  canvas.addEventListener 'mousedown', (evt) ->
    # ToolEvent.point gives us the point in project coordinates
    # lastPoint = paper.view.projectToView evt.point
    lastPoint = new paper.Point evt.offsetX, evt.offsetY

  canvas.addEventListener 'mousemove', (evt) ->
    mouseButtonDown = (evt.buttons & kLeftMouseFlag) is 1
    if mouseButtonDown and not paper.Key.isDown 'option'
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

  decay = 0.8
  paper.view.on 'frame', (evt) ->
    if panInertia.length > 0.01
      paper.view.center = paper.view.center.add panInertia
      if not paper.Key.isDown 'option'
        # panInertia = panInertia.multiply (60 * decay * evt.delta)
        delta = (panInertia.multiply decay).subtract panInertia
        delta.multiply evt.delta
        panInertia = panInertia.add delta
      do onTransform