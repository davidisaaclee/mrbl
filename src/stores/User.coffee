_ = require 'lodash'
Store = require './Store'
WorldStore = require './World'

class User extends Store
  getDefaultData: () ->
    # position: [0, 0]
    # deltaPosition: [0, 0]

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

    #   when 'didSetupWorldCanvas'
    #     {canvas, @paper} = data
    #     @data.position = @paper.view.center
    #     @data.deltaPosition = [0, 0]

      when 'didViewportTransform'
        {viewport} = data
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