_ = require 'lodash'

Dispatchable = require '../util/dispatchable'
dispatcher = require '../Dispatcher'
WorldStore = require '../stores/World'

setupCameraTool = require './paper/CameraControl'
makeTiledItem = require './paper/TiledItem'
makeRandomPath = require './paper/MakeRandomPath'
randomColor = require './paper/RandomColor'

class WorldController
  constructor: () ->
    Dispatchable this, dispatcher

  attach: (paper) ->
    @setupView paper

    WorldStore.addChangeListener @_onChange
    do @_onChange

  detach: () ->
    WorldStore.removeChangeListener @_onChange

  update: (state) ->
    if state.world.queued.entity?
      graphic = @_makeEntityGraphic @paper, state.world.queued.entity
      @dispatch 'didRegisterEntity',
        paper:
          path: graphic.path
          shadow: graphic.shadow
        entity: state.world.queued.entity


  setupView: (paper) ->
    @paper = paper

    @_shadowGroup = new paper.Group
      name: 'shadows'
    @_entityGroup = new paper.Group
      name: 'entities'

    @_backgroundGroup = @_makeBackground paper
    @_worldGroup = new paper.Group
      name: 'world'
      children: [@_backgroundGroup, @_shadowGroup, @_entityGroup]

    tool = new paper.Tool()
    @_setupAddEntityTool tool, paper
    @_setupSelectionTool tool, paper

    scope = this
    setupCameraTool paper, tool, paper.view.element,
      # viewItem: @_worldGroup
      onTransform: () ->
        scope.dispatch 'didViewportTransform',
          paper: paper



    @dispatch 'setupInspector',
      paper: paper


  _fetchState: () ->
    world: WorldStore.getAll()

  _onChange: () =>
    @state = @_fetchState()
    @update @state


  ### DRAWING ###

  _makeEntityGraphic: (paper, entity) ->
    path = @_makePaperEntity paper, entity.id, entity.position
    shadow = @_makeShadow paper, path

    data =
      entityId: entity.id

    path.data = shadow.data = data
    path.name = shadow.name = entity.id

    @_entityGroup.addChild path
    @_shadowGroup.addChild shadow

    path: path
    shadow: shadow


  _makePaperEntity: (paper, id, position) ->
    if not position?
      position = paper.view.center

    item = makeRandomPath paper,
      left: 0
      top: 0
      width: Math.random() * 450 + 50
      height: Math.random() * 450 + 50
    item.position = position
    item.fillColor =
      gradient:
        stops: [ randomColor {brightness: 0.8}
                 randomColor {brightness: 0.8} ]
      origin: item.bounds.topLeft
      destination: item.bounds.bottomRight

    return item

  _makeShadow: (paper, path) ->
    r = path.clone()
    r.fillColor = 'black'
    r.opacity = 0.6
    r.translate [30, 30]
    return r

  _makeBackground: (paper) ->
    backgroundGroup = new paper.Group
      name: 'background'
    backgroundGroup.sendToBack()

    blobProto = @_makeBackgroundBlob paper, [0, 0]
    backgroundGroup.addChild blobProto

    outerColor = new paper.Color 0, 0
    backgroundShapes =
      [-10...10]
        .map (x) ->
          [-10...10].map (y) -> new paper.Point x, y
        .reduce (acc, elm) -> acc.concat elm
        .map (coordinate) =>
          clone = blobProto.clone()
          clone.position = coordinate.multiply [800, 800]
          clone.position = clone.position.add [ Math.random() * 400
                                                Math.random() * 400 ]

          hues = [
            5
            187
            # 60
          ]

          innerColor = new paper.Color
            hue: hues[Math.floor (Math.random() * hues.length)]
            saturation: 0.3
            brightness: 0.4
          outerColor = randomColor {saturation: 0.3, brightness: 0.3}
          outerColor.alpha = 0
          clone.fillColor =
            gradient:
              stops: [innerColor, outerColor]
              radial: true
            origin: clone.bounds.center
            destination: clone.bounds.rightCenter


    rasterUrl = 'http://www.neilblevins.com/cg_education/procedural_noise/perlin_fractal_max.jpg'
    noise = new paper.Raster rasterUrl
    noise.opacity = 0.2
    noise.blendMode = 'multiply'
    noise.onLoad = () =>
      tiledNoise = makeTiledItem paper, noise,
        widthInTiles: 10
        heightInTiles: 10
        removeOriginal: true
        group: backgroundGroup


    return backgroundGroup


  _makeBackgroundBlob: (paper, position) ->
    size = 1000
    outerColor = new paper.Color 0, 0

    position = (new paper.Point Math.random(), Math.random()).add position

    r = new paper.Path.Circle
      center: position.multiply (size / 2)
      radius: size
    r.fillColor =
      gradient:
        stops: [(randomColor {saturation: 0.5, brightness: 0.6}), outerColor]
        radial: true
      origin: r.bounds.center
      destination: r.bounds.rightCenter
    r.blendMode = 'normal'
    return r


  ### TOOLS ###

  _setupAddEntityTool: (tool, paper) ->
    tool.on 'mousedown', (evt) =>
      if paper.Key.isDown 'shift'
        @dispatch 'wantsAddEntity',
          position: evt.downPoint


  _setupSelectionTool: (tool, paper) ->
    hitOptions =
      segments: true
      stroke: true
      fill: true
      tolerance: 5
    lastHit = null

    tool.onMouseMove = (evt) =>
      hitResults = @_entityGroup.hitTest evt.point, hitOptions
      hit = if hitResults? then hitResults.item.data.entityId else null

      if hit isnt lastHit
        if lastHit?
          @_handleMouseHoverEntity lastHit, 'exit'
        if hit?
          @_handleMouseHoverEntity hit, 'enter'
      @_handleMouseHoverEntity hit, 'over'
      lastHit = hit

    tool.on 'mouseup', (evt) =>
      if lastHit?
        @dispatch 'wantsEditEntity',
          id: lastHit

    tool.on 'mousedown', (evt) =>
      if not lastHit? and (not paper.Key.isDown 'shift')
        @dispatch 'wantsCancelEditEntity'

  _handleMouseHoverEntity: do ->
    reset = null
    return (entityId, state) ->
      entity =
        path: @_entityGroup.children[entityId]
        shadow: @_entityGroup.children[entityId]

      switch state
        when 'enter'
          if reset?
            do reset

          setStrokeWidth = () =>
            entity.path.strokeWidth = 3 * 1 / @paper.view.zoom
          # @_fixedEltUpdates[entity.id] = setStrokeWidth

          oldColor = entity.path.strokeColor
          oldWidth = entity.path.strokeWidth

          reset = () =>
            entity.path.strokeColor = oldColor
            entity.path.strokeWidth = oldWidth
            # delete @_fixedEltUpdates[entity.id]

          entity.path.strokeColor = '#4181FF'
          do setStrokeWidth

        when 'exit'
          if reset?
            do reset

module.exports = WorldController