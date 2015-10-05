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

  getEntity: (id) ->
    if id?
    then @entities[id]
    else null

  delegate: (payload) ->
    data = payload?.action?.data

    switch payload?.action?.actionType
      when 'setupCanvas'
        @setupCanvas data.canvasNode
        @emitChange()

      when 'wantsAddEntity'
        entity = @makeNewEntity data.position
        @dispatch 'didMakeEntity', entity: entity
        @dispatch 'beginEditEntity', id: entity.entityId
        if data.file?
          @dispatch 'wantsLoadSoundFile', file: data.file
        @emitChange()

      when 'didMouseEnterEntity'
        entity = @data.entities[data.entityId]
        if entity?
          @handleMouseEnterEntity entity
          @emitChange()

      when 'didMouseExitEntity'
        entity = @data.entities[data.entityId]
        if entity?
          @handleMouseExitEntity entity
          @emitChange()

      # when 'updateNearestEntities'
      #   @updateDistances data.distanceInfo

      when 'didViewportTransform'
        @recalculateDistances Paper.view.center
        @emitChange()


  recalculateDistances: (fromPoint) ->
    # for paths only
    distanceInfo = _ @data.entities
      .values()
      .map (entity) ->
        nearestPt = entity.path.getNearestPoint fromPoint

        distance: fromPoint.getDistance nearestPt
        entity: entity
      .filter (elm) ->
        elm.distance < (Paper.view.size.width / 2)
      .map (elm) ->
        _.assign elm,
          viewDistanceRatio: elm.distance / Paper.view.size.width
      .value()

    @dispatch 'didUpdateNearestEntities', distanceInfo



  # updateDistances: (inView) ->
  #   inView
  #     .forEach (distanceInfo) =>
  #       @data.entities[distanceInfo.id].path.opacity = distanceInfo.viewDistanceRatio
  #       @data.entities[distanceInfo.id].shadow.opacity = distanceInfo.viewDistanceRatio * 0.5


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

  setupCanvas: (canvasNode) ->
    canvas = canvasNode
    Paper.setup canvas

    @data.paper.layers.shadows = new Paper.Layer()
    @data.paper.layers.entities = new Paper.Layer()

  handleMouseEnterEntity: (entity) ->
    entity.path.strokeColor = 'blue'

  handleMouseExitEntity: (entity) ->
    entity.path.strokeColor = 'black'

  _makePaperEntity: (id, position = Paper.view.center) ->
    item = makeRandomPath Paper,
      left: 0
      top: 0
      width: 500
      height: 500
    item.position = position
    item.strokeColor = 'black'
    item.data.entityId = id

    return item

  _makeShadow: (path) ->
    r = path.clone()
    r.fillColor = 'black'
    r.opacity = 0.3
    r.translate [30, 30]
    return r

module.exports = new World()