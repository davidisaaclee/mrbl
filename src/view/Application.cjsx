_ = require 'lodash'
React = require 'react'
Paper = require 'paper'

WorldStore = require '../stores/World'
EditorStore = require '../stores/Editor'
UserStore = require '../stores/User'

InspectorController = require './InspectorController'
WorldController = require './WorldController'
VolumeControl = require './VolumeControl'

makeRandomPath = require './paper/MakeRandomPath'
setupCameraTool = require './paper/CameraControl'

Dispatchable = require '../util/Dispatchable'
dispatcher = require '../Dispatcher'

randomColor = require './paper/RandomColor'

Application = React.createClass
  displayName: 'Application'

  shadowAmount: [20, 20]

  getInitialState: () ->
    world: WorldStore.getAll()
    editor: EditorStore.getAll()
    user: UserStore.getAll()
    app:
      showOverlays: false

  componentDidMount: () ->
    Dispatchable this, dispatcher
    WorldStore.addChangeListener @_onChange
    EditorStore.addChangeListener @_onChange
    UserStore.addChangeListener @_onChange

    canvas = @refs.canvas.getDOMNode()
    inspector = @refs.inspector.getDOMNode()

    @fieldPaperScope = @setupField canvas
    @inspectorPaperScope = @setupInspector inspector

    canvas.style.width = '100%'
    canvas.style.height = '100%'
    inspector.style.width = '100%'
    inspector.style.height = '100%'

    @fieldPaperScope.view.viewSize = [canvas.offsetWidth, canvas.offsetHeight]
    @inspectorPaperScope.view.viewSize = [inspector.offsetWidth, inspector.offsetHeight]


  setupField: (canvasNode) ->
    fieldPaper = new Paper.PaperScope()
    fieldPaper.setup canvasNode

    (new WorldController()).attach fieldPaper
    return fieldPaper

  setupInspector: (canvasNode) ->
    inspectorPaper = new Paper.PaperScope()
    inspectorPaper.setup canvasNode

    (new InspectorController()).attach inspectorPaper
    return inspectorPaper

  handleDragover: (evt) ->
    evt.stopPropagation()
    evt.preventDefault()
    evt.dataTransfer.dropEffect = 'copy'

  handleDrop: (evt) ->
    evt.stopPropagation()
    evt.preventDefault()

    file = evt.dataTransfer.files[0]
    pt = new @fieldPaperScope.Point evt.clientX, evt.clientY

    if file?
      @dispatch 'wantsAddEntity',
        file: file
        position: @fieldPaperScope.view.viewToProject pt

  render: () ->
    <div id="frame"
         ref="frame"
         onMouseEnter={() => @setState {app: {showOverlays: true}}}}
         onMouseOut={(evt) =>
          @setState {app: {showOverlays: evt.relatedTarget? and evt.relatedTarget isnt @refs.canvas.getDOMNode()}}}>
      <div id="container">
        <div id="mg-overlays">
          <VolumeControl id="mg-master-volume"
                         className={if @state.app.showOverlays then 'visible' else 'hidden'}
                         source={@props.audioSource}>
          </VolumeControl>
        </div>
        <div id="mg-app"
             className="mg-app"
             ref="container">
          <canvas className="mg-field"
                  id="mg-field-canvas"
                  ref="canvas"
                  style={@props.style}
                  onDragOver={@handleDragover}
                  onDrop={@handleDrop}
                  data-resize="true">
          </canvas>
          <canvas className={"mg-inspector" + if @state.editor.isActive then ' visible' else ' hidden'}
                  id="mg-inspector-canvas"
                  ref="inspector"
                  style={@props.style}
                  onDragOver={@handleDragover}
                  onDrop={@handleDrop}
                  data-resize="true">
          </canvas>
        </div>
      </div>
    </div>

  canvasDimensions: () ->
    @refs.container.getDOMNode().getBoundingClientRect()

  _onChange: () ->
    @setState
      world: WorldStore.getAll()
      editor: EditorStore.getAll()
      user: UserStore.getAll()

    # @_updateBackground()

  # TODO: some controller for user-specific actions?
  # _updateBackground: () ->
  #   @backgroundLayer?.translate (new Paper.Point @state.user.deltaPosition).multiply 0.5


module.exports = Application