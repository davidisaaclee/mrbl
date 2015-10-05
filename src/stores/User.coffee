_ = require 'lodash'
Store = require './Store'
WorldStore = require './World'

class User extends Store
  getDefaultData: () ->
    position: [0, 0]
    deltaPosition: [0, 0]

  delegate: (payload) ->
    data = payload?.action?.data

    switch payload?.action?.actionType
      when 'didSetupWorldCanvas'
        {canvas, paper} = data
        console.log paper
        @data.position = paper.view.center
        @data.deltaPosition = [0, 0]

      when 'didViewportTransform', 'didAddEntity'
        paper = WorldStore.data.paper.scope
        deltaPosition = paper.view.center.subtract @data.position
        @data.position = paper.view.center
        @data.deltaPosition = deltaPosition
        @recalculateDistances paper.view.center, paper.view.size
        @emitChange()


  recalculateDistances: (fromPoint, withinBox) ->
    # for paths only
    distanceInfo = _ WorldStore.data.entities
      .values()
      .map (entity) ->
        nearestPt = entity.path.getNearestPoint fromPoint

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