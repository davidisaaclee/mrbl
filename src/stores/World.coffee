_ = require 'lodash'
Promise = (require 'es6-promise').Promise
Store = require './Store'
Paper = require 'paper'

makeRandomPath = require '../view/paper/MakeRandomPath'

class World extends Store
  constructor: () ->
    super arguments...
    @entityCount = 0


  getDefaultData: () ->
    entities: {}
    paper:
      layers: {}
      scope: null

  getEntity: (id) ->
    if id?
    then @data.entities[id]
    else null

  delegate: (payload) ->
    data = payload?.action?.data

    switch payload?.action?.actionType
      when 'setupCanvas'
        @setupCanvas data.canvasNode
        @emitChange()

      when 'wantsAddEntity'
        entity = @makeNewEntity data.position
        @dispatch 'didAddEntity', entity: entity
        @dispatch 'wantsEditEntity', id: entity.entityId
        if data.file?
          @dispatch 'wantsLoadSoundFile', file: data.file
        @emitChange()

      when 'didMouseEnterEntity'
        entity = @data.entities[data.entityId]
        if entity?
          @handleMouseHoverEntity entity, 'enter'
          @emitChange()

      when 'didMouseExitEntity'
        entity = @data.entities[data.entityId]
        if entity?
          @handleMouseHoverEntity entity, 'exit'
          @emitChange()

      when 'wantsEditEntity'
        {id} = data
        entity = @getEntity id
        if entity?
          @focusOnItem entity.path
            .then () =>
              @dispatch 'didBeginEditEntity', entity: entity
        else
          console.error 'editing nonexistant entity', id

      when 'wantsFocusOnItem'
        {item, offset} = data
        @focusOnItem item, offset


  makeNewEntity: (position) ->
    id = "entity-#{@entityCount++}"

    path = @_makePaperEntity id, position
    shadow = @_makeShadow path

    @data.paper.layers.entities.addChild path
    @data.paper.layers.shadows.addChild shadow

    @data.entities[id] =
      path: path
      shadow: shadow
      entityId: id

  setupCanvas: (canvas) ->
    @paper = new Paper.PaperScope()
    @paper.setup canvas

    @data.paper.scope = @paper

    @data.paper.layers.shadows = new Paper.Layer()
    @data.paper.layers.entities = new Paper.Layer()

    @dispatch 'didSetupWorldCanvas',
      canvas: canvas
      paper: @data.paper.scope

  focusOnItem: (item, offset = [0, 0], zoomFactor = 0.4) ->
    view = item.project.view

    point = item.position

    # nudge item up a little bit
    offset = [0, view.viewSize.height * 0.08]
    point = point.add offset

    widthZoomDst = view.viewSize.width / item.bounds.width
    heightZoomDst = view.viewSize.height / item.bounds.height

    zoomToFitDst = Math.min widthZoomDst, heightZoomDst

    return new Promise (resolve, reject) =>
      otherIsDone = false # lol

      finish = () ->
        if otherIsDone?
          do resolve
        else
          otherIsDone = true

      @_animatePanTo point, view, 0.2
        .then finish, reject
      @_animateZoom (zoomToFitDst * zoomFactor), view, 0.2
        .then finish, reject

  _animatePanTo: (dst, view, duration) ->
    return new Promise (resolve, reject) =>
      elapsed = 0
      src = view.center
      travel = dst.subtract src

      animatePan = (evt) =>
        elapsed += evt.delta
        travelRatio = elapsed / duration

        if travelRatio >= 1
          travelRatio = 1
          view.center = dst
          view.off 'frame', animatePan

          @dispatch 'didViewportTransform'
          do resolve

          return

        view.center = src.add (travel.multiply travelRatio)

      view.on 'frame', animatePan

  _animateZoom: (zoomDst, view, duration) ->
    return new Promise (resolve, reject) =>
      elapsed = 0
      src = view.zoom
      travel = zoomDst - src

      animateZoomFrame = (evt) =>
        elapsed += evt.delta
        travelRatio = elapsed / duration

        if travelRatio >= 1
          travelRatio = 1
          view.zoom = zoomDst
          view.off 'frame', animateZoomFrame

          @dispatch 'didViewportTransform'
          do resolve

          return

        view.zoom = src + (travel * travelRatio)

      view.on 'frame', animateZoomFrame

  handleMouseHoverEntity: do ->
    reset = null
    return (entity, state) =>
      switch state
        when 'enter'
          if reset?
            do reset

          oldColor = entity.path.strokeColor
          reset = () -> entity.path.strokeColor = oldColor
          entity.path.strokeColor = 'blue'
        when 'exit'
          if reset?
            do reset


  _makePaperEntity: (id, position) ->
    if not position?
      position = @state.paper.scope.view.center

    randomColor = (options = {}) ->
      options = _.defaults options,
        hue: Math.random() * 360
        saturation: Math.random()
        brightness: Math.random()

      new Paper.Color options

    item = makeRandomPath @paper,
      left: 0
      top: 0
      width: Math.random() * 2000
      height: Math.random() * 2000
    item.position = position
    # item.strokeColor = 'black'
    item.fillColor =
      gradient:
        stops: [ randomColor {brightness: 0.8}
                 randomColor {brightness: 0.8} ]
      origin: item.bounds.topLeft
      destination: item.bounds.bottomRight
    item.data.entityId = id

    return item

  _makeShadow: (path) ->
    r = path.clone()
    r.fillColor = 'black'
    r.opacity = 0.3
    r.translate [30, 30]
    return r

module.exports = new World()