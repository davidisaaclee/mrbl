Store = require './Store'
WorldStore = require './World'
k = require '../Constants'

class Editor extends Store
  getDefaultData: () ->
    r = activeEntityId: null
    Object.defineProperty r, 'activeEntity',
      get: () -> WorldStore.getEntity @activeEntityId
    return r


  delegate: (payload) ->
    data = payload?.action?.data

    switch payload?.action?.actionType
      when 'beginEditEntity'
        @setEditEntity data.id
        @emitChange()

      when 'cancelEditEntity'
        @setEditEntity null
        @emitChange()

      when 'wantsLoadSoundFile'
        if @data.activeEntityId?
          reader = new FileReader()
          reader.onload = (evt) => @loadSoundBuffer evt
          reader.readAsArrayBuffer data.file


  setEditEntity: (entityId) ->
    @data.activeEntityId = entityId


  loadSoundBuffer: (evt) ->
    data = evt.target.result
    k.AudioContext.decodeAudioData data, (buffer) =>
      @dispatch 'loadBufferIntoEntity',
        buffer: buffer
        entity: @data.activeEntity


module.exports = new Editor()