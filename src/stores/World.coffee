_ = require 'lodash'
Promise = (require 'es6-promise').Promise
Store = require './Store'
Paper = require 'paper'

makeRandomPath = require '../view/paper/MakeRandomPath'

class World extends Store
  constructor: () ->
    super arguments...
    @entityCount = 0
    @_fixedEltUpdates = {}


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
          @focusOnItem entity.path, [0, entity.path.bounds.height * 0.1]
            .then () =>
              @dispatch 'didBeginEditEntity', entity: entity
        else
          console.error 'editing nonexistant entity', id

      when 'wantsFocusOnItem'
        {item, offset} = data
        @focusOnItem item, offset

      when 'didViewportTransform'
        @_updateFixedElements()


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
    # offset = [0, view.viewSize.height * 0.08]
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

  _animatePanTo: (dst, view, speed) ->
    return new Promise (resolve, reject) =>
      elapsed = 0
      src = view.center
      travel = dst.subtract src

      # duration = travel.length / speed
      duration = speed

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

  _animateZoom: (zoomDst, view, speed) ->
    return new Promise (resolve, reject) =>
      elapsed = 0
      src = view.zoom
      travel = zoomDst - src

      # duration = travel / speed
      duration = speed

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
    return (entity, state) ->
      switch state
        when 'enter'
          if reset?
            do reset

          setStrokeWidth = () =>
            entity.path.strokeWidth = 3 * 1 / @data.paper.scope.view.zoom
          @_fixedEltUpdates[entity.id] = setStrokeWidth

          oldColor = entity.path.strokeColor
          oldWidth = entity.path.strokeWidth

          reset = () =>
            entity.path.strokeColor = oldColor
            entity.path.strokeWidth = oldWidth
            delete @_fixedEltUpdates[entity.id]

          entity.path.strokeColor = '#4181FF'
          do setStrokeWidth

        when 'exit'
          if reset?
            do reset

  _updateFixedElements: () ->
    _.values @_fixedEltUpdates
      .forEach (fn) -> do fn


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
      width: Math.random() * 450 + 50
      height: Math.random() * 450 + 50
    item.position = position
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
    r.opacity = 0.6
    r.translate [30, 30]
    return r

module.exports = new World()