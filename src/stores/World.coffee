_ = require 'lodash'
Promise = (require 'es6-promise').Promise
Store = require './Store'
Paper = require 'paper'

RedEntity = require '../entities/RedEntity'

makeRandomPath = require '../view/paper/MakeRandomPath'

class World extends Store
  constructor: () ->
    super arguments...
    @entityCount = 0
    @_fixedEltUpdates = {}


  getDefaultData: () ->
    entities: {}
    # paper:
    #   layers: {}
    #   scope: null
    queued:
      entity: null

  getEntity: (id) ->
    if id?
    then @data.entities[id]
    else null

  delegate: (payload) ->
    data = payload?.action?.data

    switch payload?.action?.actionType
      when 'wantsAddEntity'
        entity = @makeNewEntity data.position

        @dispatch 'wantsRegisterEntity',
          entity: entity

        if data.file?
          @dispatch 'wantsLoadSoundFile',
            entity: entity
            file: data.file

        # temporary: load default if no file
        else
          @dispatch 'loadBufferIntoEntity',
            entity: entity
            buffer: null

      when 'wantsRegisterEntity'
        @data.queued.entity = data.entity
        @emitChange()

      when 'didRegisterEntity'
        {entity, paper} = data
        @data.queued.entity = null
        @data.entities[entity.id] = entity
        @data.entities[entity.id].paper = paper
        @dispatch 'didAddEntity',
          entity: entity
        @emitChange()

      # when 'wantsFocusOnItem'
      #   {item, offset} = data
      #   @focusOnItem item, offset


  makeNewEntity: (position) ->
    id = "entity-#{@entityCount++}"

    # entity =
    #   id: id
    #   position: position
    entity = new RedEntity id, position
    return entity


  # TODO: move these focus methods elsewhere

  # focusOnItem: (item, offset = [0, 0], zoomFactor = 0.4) ->
  #   view = item.project.view

  #   point = item.position

  #   # nudge item up a little bit
  #   # offset = [0, view.viewSize.height * 0.08]
  #   point = point.add offset

  #   widthZoomDst = view.viewSize.width / item.bounds.width
  #   heightZoomDst = view.viewSize.height / item.bounds.height

  #   zoomToFitDst = Math.min widthZoomDst, heightZoomDst

  #   return new Promise (resolve, reject) =>
  #     otherIsDone = false # lol

  #     finish = () ->
  #       if otherIsDone?
  #         do resolve
  #       else
  #         otherIsDone = true

  #     @_animatePanTo point, view, 0.2
  #       .then finish, reject
  #     @_animateZoom (zoomToFitDst * zoomFactor), view, 0.2
  #       .then finish, reject

  # _animatePanTo: (dst, view, speed) ->
  #   return new Promise (resolve, reject) =>
  #     elapsed = 0
  #     src = view.center
  #     travel = dst.subtract src

  #     # duration = travel.length / speed
  #     duration = speed

  #     animatePan = (evt) =>
  #       elapsed += evt.delta
  #       travelRatio = elapsed / duration

  #       if travelRatio >= 1
  #         travelRatio = 1
  #         view.center = dst
  #         view.off 'frame', animatePan

  #         @dispatch 'didViewportTransform'
  #         do resolve

  #         return

  #       view.center = src.add (travel.multiply travelRatio)

  #     view.on 'frame', animatePan

  # _animateZoom: (zoomDst, view, speed) ->
  #   return new Promise (resolve, reject) =>
  #     elapsed = 0
  #     src = view.zoom
  #     travel = zoomDst - src

  #     # duration = travel / speed
  #     duration = speed

  #     animateZoomFrame = (evt) =>
  #       elapsed += evt.delta
  #       travelRatio = elapsed / duration

  #       if travelRatio >= 1
  #         travelRatio = 1
  #         view.zoom = zoomDst
  #         view.off 'frame', animateZoomFrame

  #         @dispatch 'didViewportTransform'
  #         do resolve

  #         return

  #       view.zoom = src + (travel * travelRatio)

  #     view.on 'frame', animateZoomFrame


module.exports = new World()