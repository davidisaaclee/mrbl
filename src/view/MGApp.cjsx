_ = require 'lodash'
React = require 'react'
Paper = require 'paper'

WorldStore = require '../stores/World'
EditorStore = require '../stores/Editor'
UserStore = require '../stores/User'

InspectorController = require './InspectorController'
WorldController = require './WorldController'

makeRandomPath = require './paper/MakeRandomPath'
setupCameraTool = require './paper/CameraControl'

Dispatchable = require '../util/Dispatchable'
dispatcher = require '../Dispatcher'

randomColor = require './paper/RandomColor'

MGApp = React.createClass
  displayName: 'MGApp'

  shadowAmount: [20, 20]

  getInitialState: () ->
    world: WorldStore.getAll()
    editor: EditorStore.getAll()
    user: UserStore.getAll()

  componentDidMount: () ->
    Dispatchable this, dispatcher
    WorldStore.addChangeListener @_onChange
    EditorStore.addChangeListener @_onChange
    UserStore.addChangeListener @_onChange

    @setupCanvas @refs.canvas.getDOMNode()
    @setupInspector @refs.inspector.getDOMNode()

  setupCanvas: (canvasNode) ->
    @_paper = new Paper.PaperScope()
    @_paper.setup canvasNode

    (new WorldController()).attach @_paper
    # (new InspectorController()).attach @_paper

  setupInspector: (canvasNode) ->
    inspectorPaper = new Paper.PaperScope()
    inspectorPaper.setup canvasNode

    (new InspectorController()).attach inspectorPaper



  handleDragover: (evt) ->
    evt.stopPropagation()
    evt.preventDefault()
    evt.dataTransfer.dropEffect = 'copy'

  handleDrop: (evt) ->
    evt.stopPropagation()
    evt.preventDefault()

    file = evt.dataTransfer.files[0]
    pt = new @_paper.Point evt.clientX, evt.clientY

    if file?
      @dispatch 'wantsAddEntity',
        file: file
        position: @_paper.view.viewToProject pt

  render: () ->
    <div id="mg-app"
         className="mg-app"
         ref="container">
      <canvas className="mg-field"
              id="mg-field-canvas"
              ref="canvas"
              style={@props.style}
              onDragOver={@handleDragover}
              onDrop={@handleDrop}
              width={@props.width}
              height={@props.height}
              data-resize="true">
      </canvas>
      <canvas className={"mg-inspector" + if @state.editor.isActive then ' visible' else ' hidden'}
              id="mg-inspector-canvas"
              ref="inspector"
              style={@props.style}
              onDragOver={@handleDragover}
              onDrop={@handleDrop}
              width={@props.width}
              height={@props.height}
              data-resize="true">
      </canvas>
    </div>



  _onChange: () ->
    @setState
      world: WorldStore.getAll()
      editor: EditorStore.getAll()
      user: UserStore.getAll()

    # @_updateBackground()

  # TODO: some controller for user-specific actions?
  # _updateBackground: () ->
  #   @backgroundLayer?.translate (new Paper.Point @state.user.deltaPosition).multiply 0.5


module.exports = MGApp