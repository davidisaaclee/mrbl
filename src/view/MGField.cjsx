_ = require 'lodash'
React = require 'react'
Paper = require 'paper'

WorldStore = require '../stores/World'
EditorStore = require '../stores/Editor'

makeRandomPath = require './paper/MakeRandomPath'
setupCameraTool = require './paper/CameraControl'

Dispatchable = require '../util/Dispatchable'
dispatcher = require '../Dispatcher'

randomColor = () ->
  new Paper.Color
    hue: Math.random() * 360
    saturation: Math.random()
    brightness: Math.random()

MGField = React.createClass
  displayName: 'MGField'

  shadowAmount: [20, 20]

  getInitialState: () ->
    world: WorldStore.getAll()
    editor: EditorStore.getAll()

  componentDidMount: () ->
    Dispatchable this, dispatcher
    WorldStore.addChangeListener @_onChange
    EditorStore.addChangeListener @_onChange
    @setupCanvas @refs.canvas.getDOMNode()

  setupCanvas: (canvasNode) ->
    @dispatch 'setupCanvas', canvasNode: canvasNode

    # [0...3].map (idx) =>
    #   # @makeEntity idx
    #   @dispatch 'wantsAddEntity',
    #     position: Paper.view.center

    tool = new Paper.Tool()
    @setupAddEntityTool tool, canvasNode
    @setupSelectionTool tool, canvasNode
    setupCameraTool tool, canvasNode, () =>
      @dispatch 'didViewportTransform'


  setupAddEntityTool: (tool) ->
    tool.on 'mousedown', (evt) =>
      if Paper.Key.isDown 'shift'
        @dispatch 'wantsAddEntity',
          position: evt.downPoint


  setupSelectionTool: (tool) ->
    hitOptions =
      segments: true
      stroke: true
      fill: true
      tolerance: 5
    lastHit = null

    tool.onMouseMove = (evt) =>
      for entity in @state.world.paper.layers.entities.children
        hitResults = entity.hitTest evt.point, hitOptions
        if hitResults?
          if lastHit isnt hitResults.item
            if lastHit?
              @dispatch 'didMouseExitEntity',
                entityId: lastHit.data.entityId
            @dispatch 'didMouseEnterEntity',
              entityId: hitResults.item.data.entityId

          lastHit = hitResults.item
          @dispatch 'didMouseOverEntity',
            entityId: hitResults.item.data.entityId

          lastHit = hitResults.item
          return

      # didn't hit anything, set it to null
      if lastHit?
        @dispatch 'didMouseExitEntity',
          entityId: lastHit.data.entityId
        lastHit = null

    tool.on 'mouseup', (evt) =>
      if lastHit?
        @dispatch 'beginEditEntity',
          id: lastHit.data.entityId
      # else
      #   @dispatch 'cancelEditEntity'

    tool.on 'mousedown', (evt) =>
      if not lastHit? and (not Paper.Key.isDown 'shift')
        @dispatch 'cancelEditEntity'


  canvasStyle: () ->
    width: @props.width
    height: @props.height

  handleDragover: (evt) ->
    evt.stopPropagation()
    evt.preventDefault()
    evt.dataTransfer.dropEffect = 'copy'

  handleDrop: (evt) ->
    evt.stopPropagation()
    evt.preventDefault()

    file = evt.dataTransfer.files[0]
    pt = new Paper.Point evt.clientX, evt.clientY

    if file?
      @dispatch 'wantsAddEntity',
        file: file
        position: Paper.view.viewToProject pt

  render: () ->
    <canvas className="mg-field"
            id="mg-field-canvas"
            width={@props.width}
            height={@props.height}
            onDragOver={@handleDragover}
            onDrop={@handleDrop}
            resize
            ref="canvas">
    </canvas>

  _onChange: () ->
    @setState
      world: WorldStore.getAll()
      editor: EditorStore.getAll()


module.exports = MGField