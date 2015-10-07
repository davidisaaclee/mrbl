Paper = require 'paper'
Store = require './Store'
WorldStore = require './World'
k = require '../Constants'

# definitely more of a controller;
#  but aren't controllers just lightweight stores?
class Editor extends Store
  getDefaultData: () ->
    activeEntityId: null
    activeEntity: null
    isActive: false
    queuedEntity: null
    events:
      wantsEdit: false
      wantsCancelInspector: false


  delegate: (payload) ->
    data = payload?.action?.data

    switch payload?.action?.actionType
      when 'wantsEditEntity'
        {id} = data.id
        entity = WorldStore.getEntity data.id
        if entity?
          @data.events.wantsEdit = true
          @data.queuedEntity = entity
          @emitChange()

      when 'didBeginEditEntity'
        {entity} = data
        @data.events.wantsEdit = false
        @data.activeEntity = entity
        @data.isActive = true
        @emitChange()

      when 'wantsCancelEditEntity'
        @data.events.wantsCancel = true
        @emitChange()

      when 'didCancelEditEntity'
        @data.events.wantsCancel = false
        @data.isActive = false
        @emitChange()



  setEditEntity: (entityId) ->
    @data.activeEntityId = entityId
    @data.activeEntity = WorldStore.getEntity @data.activeEntityId



module.exports = new Editor()