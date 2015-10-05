_ = require 'lodash'
React = require 'react'
Paper = require 'paper'

WorldStore = require '../stores/World'
EditorStore = require '../stores/Editor'
UserStore = require '../stores/User'

makeRandomPath = require './paper/MakeRandomPath'
setupCameraTool = require './paper/CameraControl'

Dispatchable = require '../util/Dispatchable'
dispatcher = require '../Dispatcher'

randomColor = (options = {}) ->
  options = _.defaults options,
    hue: Math.random() * 360
    saturation: Math.random()
    brightness: Math.random()

  new Paper.Color options

MGField = React.createClass
  displayName: 'MGField'

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

  setupCanvas: (canvasNode) ->
    @dispatch 'setupCanvas', canvasNode: canvasNode

    paper = @state.world.paper.scope

    @backgroundLayer = new paper.Layer
      name: 'background'
    @backgroundLayer.sendToBack()

    backgroundShapes =
      [-10...10]
        .map (x) ->
          [-10...10].map (y) -> new paper.Point x, y
        .reduce (acc, elm) -> acc.concat elm
        .map (coordinate) ->
          size = 1000
          outerColor = new paper.Color 0, 0

          coordinate =
            coordinate.add [Math.random(),
                            Math.random()]

          r = new paper.Path.Circle
            center: coordinate.multiply (size / 2)
            radius: size
          r.fillColor =
            gradient:
              stops: [(randomColor {saturation: 0.5, brightness: 0.6}), outerColor]
              radial: true
            origin: r.bounds.center
            destination: r.bounds.rightCenter
          return r
        .forEach (circle) =>
          @backgroundLayer.addChild circle

    tool = new paper.Tool()
    @setupAddEntityTool tool, canvasNode
    @setupSelectionTool tool, canvasNode
    setupCameraTool paper, tool, canvasNode, () =>
      @dispatch 'didViewportTransform',
        paper: paper


  setupAddEntityTool: (tool) ->
    tool.on 'mousedown', (evt) =>
      if @state.world.paper.scope.Key.isDown 'shift'
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
        @dispatch 'wantsEditEntity',
          id: lastHit.data.entityId
      # else
      #   @dispatch 'cancelEditEntity'

    tool.on 'mousedown', (evt) =>
      if not lastHit? and (not @state.world.paper.scope.Key.isDown 'shift')
        @dispatch 'cancelEditEntity'


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
        position: @state.world.paper.scope.view.viewToProject pt

  render: () ->
    <canvas className="mg-field"
            id="mg-field-canvas"
            style={@props.style}
            width={@props.width}
            height={@props.height}
            onDragOver={@handleDragover}
            onDrop={@handleDrop}
            resize
            ref="canvas">
    </canvas>

  _update: () ->
    @backgroundLayer?.translate (new Paper.Point @state.user.deltaPosition).multiply 0.5

  _onChange: () ->
    @setState
      world: WorldStore.getAll()
      editor: EditorStore.getAll()
      user: UserStore.getAll()

    @_update()


module.exports = MGField