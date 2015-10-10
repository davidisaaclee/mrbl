_ = require 'lodash'
Store = require './Store'
WorldStore = require './World'

class User extends Store
  getDefaultData: () ->
    position: null
    deltaPosition: [0, 0]

  delegate: (payload) ->
    data = payload?.action?.data

    switch payload?.action?.actionType
      when 'wantsEditEntity'
        {id} = data
        entity = WorldStore.getEntity id
        if entity?
          @dispatch 'didBeginEditEntity', entity: entity
        #   @focusOnItem entity.path, [0, entity.path.bounds.height * 0.1]
        #     .then () =>
        #       @dispatch 'didBeginEditEntity', entity: entity
        # else
        #   console.error 'editing nonexistant entity', id

      when 'didViewportTransform'
        {viewport} = data

        @data.deltaPosition =
          if @data.position?
          then viewport.center.subtract @data.position
          else [0, 0]
        @data.position = viewport.center

        @recalculateDistances viewport.center, viewport.size
        @emitChange()

      when 'didRegisterEntity'
        {paper: {scope}} = data
        viewport = scope.view
        @recalculateDistances viewport.center, viewport.size
        @emitChange()


  recalculateDistances: (fromPoint, withinBox) ->
    # for paths only
    distanceInfo = _ WorldStore.data.entities
      .values()
      .map (entity) ->
        nearestPt = entity.paper.path.getNearestPoint fromPoint

        distance: fromPoint.getDistance nearestPt
        entity: entity
      .filter (elm) ->
        elm.distance < (withinBox.width / 2)
      .map (elm) ->
        _.assign elm,
          viewDistanceRatio: elm.distance / withinBox.width
      .value()

    @dispatch 'didUpdateNearestEntities', distanceInfo

module.exports = new User()