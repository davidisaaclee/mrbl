_ = require 'lodash'

###
This is currently more complex than it needs to be, since I mixed together
camera control for operating on groups and the master viewport into the same
functions...

Camera control on groups didn't work out as planned (problem with adding
children after transform), so we no longer need that part of the code. I'll
get rid of it sometime.
###


kLeftMouseFlag = 1

module.exports = cameraControlTool = (paper, tool, canvas, options) ->
  options = _.defaults options,
    onTransform: _.identity
    viewItem: paper.view

  setupZoom paper, tool, canvas, options
  setupPan paper, tool, canvas, options

setupZoom = (paper, tool, canvas, options) ->
  zoom = (amount, pt) ->
    getZoom =
      if options.viewItem.zoom?
      then () -> options.viewItem.zoom
      else () -> options.viewItem.scaling.x
    setZoom =
      if options.viewItem.zoom?
      then (amt, center) ->
        scrollAmount = options.viewItem.center.subtract center
        options.viewItem.scrollBy scrollAmount
        zoomDelta = amt / options.viewItem.zoom
        options.viewItem.zoom = amt
        options.viewItem.scrollBy scrollAmount.negate().multiply zoomDelta
      else (amt, center) ->
        options.viewItem.scale [1 / amt, 1 / amt], center

    newZoom = getZoom() * amount
    newZoom = Math.max (Math.min newZoom, 5), 0.5

    if newZoom != getZoom()
      setZoom newZoom, pt
      do options.onTransform

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


setupPan = (paper, tool, canvas, options) ->
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

  setCenter =
    if options.viewItem.center?
    then (pt) -> options.viewItem.center = pt
    else (pt) ->
      delta = options.viewItem.position.subtract pt
      options.viewItem.position = delta.add options.viewItem.position
  getCenter =
    if options.viewItem.center?
    then () -> options.viewItem.center
    else () -> options.viewItem.position

  paper.view.on 'frame', (evt) ->
    if panInertia.length > 0.01
      # options.viewItem.center = options.viewItem.center.add panInertia
      setCenter (getCenter().add panInertia)
      if not paper.Key.isDown 'option'
        # panInertia = panInertia.multiply (60 * decay * evt.delta)
        delta = (panInertia.multiply decay).subtract panInertia
        delta.multiply evt.delta
        panInertia = panInertia.add delta
      do options.onTransform