Paper = require 'paper'

module.exports = cameraControlTool = (tool, canvas, onTransform) ->
  if not onTransform?
    onTransform = ->

  panInertia = new Paper.Point 0, 0

  zoom = (amount, pt) ->
    scrollAmount = Paper.view.center.subtract pt
    Paper.view.scrollBy scrollAmount
    Paper.view.zoom *= amount
    Paper.view.scrollBy scrollAmount.negate().multiply amount
    do onTransform

  canvas.addEventListener 'mousewheel', (evt) ->
    evt.stopPropagation()
    evt.preventDefault()

    if Paper.Key.isDown 'option'
      delta = new Paper.Point evt.deltaX, evt.deltaY
      panInertia = delta

    else
      mouseOffset = new Paper.Point evt.offsetX, evt.offsetY
      projMouseOffset = Paper.view.viewToProject mouseOffset

      delta = evt.deltaY / 100.0
      delta *= 0.8
      zoom (1 + delta), projMouseOffset


  lastScroll = new Paper.Point 0, 0
  tool.on 'mousedrag', (evt) ->
    if Paper.Key.isDown 'option'
      mouseOffset = new Paper.Point evt.offsetX, evt.offsetY
      projMouseOffset = Paper.view.viewToProject mouseOffset
      zoom 1 + 2 * evt.delta.x / Paper.view.size.width, Paper.view.center
    else
      lastPointAdjust = evt.lastPoint.add lastScroll
      scrollAmount = lastPointAdjust.subtract evt.point
      panInertia = panInertia.add scrollAmount.multiply 0.4

  window.addEventListener 'focus', () ->
    panInertia = new Paper.Point 0, 0

  tool.on 'mousedown', (evt) ->
    panInertia = new Paper.Point 0, 0

  Paper.view.on 'frame', (evt) ->
    if panInertia.length > 0.01
      Paper.view.scrollBy panInertia
      if not Paper.Key.isDown 'option'
        panInertia = panInertia.multiply (58 * evt.delta)
      do onTransform
