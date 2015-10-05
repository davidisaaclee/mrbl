_ = require 'lodash'
React = require 'react'
Paper = require 'paper'

# WorldStore = require '../stores/World'
EditorStore = require '../stores/Editor'

# makeRandomPath = require './paper/MakeRandomPath'
# setupCameraTool = require './paper/CameraControl'

Dispatchable = require '../util/Dispatchable'
dispatcher = require '../Dispatcher'


MGInspector = React.createClass
  displayName: 'MGInspector'

  getInitialState: () ->
    EditorStore.getAll()

  componentDidMount: () ->
    Dispatchable this, dispatcher
    EditorStore.addChangeListener @_onChange
    @setupCanvas @refs.canvas.getDOMNode()

  setupCanvas: (canvasNode) ->
    @dispatch 'setupInspectorCanvas', canvasNode: canvasNode

  render: () ->
    <canvas className={"mg-inspector-canvas " + if @props.hidden then 'hidden' else 'visible'}
            id="mg-inspector-canvas"
            ref="canvas"
            {...@inspectorCanvasAttributes()}>
    </canvas>

  inspectorContainerStyle: () ->
    dimensions =
      if @props['data-fullscreen']
      then @_screenDimensions()
      else
        width: @props.width
        height: @props.height

    _.extend @props.style, _.extend dimensions,
      display: 'flex'
      alignItems: 'center'
      justifyContent: 'center'


  inspectorCanvasAttributes: () ->
    style = _.extend @props.style,
      pointerEvents: 'auto'

    # if @props.hidden
    #   display: 'none'
    #   pointerEvents: 'none'
    # else
    #   display: 'initial'
    #   pointerEvents: 'auto'
    #   zIndex: 2

    ratio = 1.77 # 16:9 fo lyfe
    margin = 0.2

    maxWidth = @_screenDimensions().width * (1 - margin)
    maxHeight = @_screenDimensions().height * (1 - margin)

    dim = widthDominant = do ->
      width: maxWidth
      height: maxWidth / ratio

    if widthDominant.height > maxHeight
      dim = heightDominant = do ->
        width: maxHeight * ratio
        height: maxHeight

    _.extend dim,
      style: style


  _onChange: () ->
    @setState EditorStore.getAll()


  _screenDimensions: () ->
    width: Math.max(document.documentElement.clientWidth, window.innerWidth || 0)
    height: Math.max(document.documentElement.clientHeight, window.innerHeight || 0)


module.exports = MGInspector