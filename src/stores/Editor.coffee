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

  delegate: (payload) ->
    data = payload?.action?.data

    switch payload?.action?.actionType
      when 'setupInspectorCanvas'
        {canvasNode} = data
        @setupCanvas canvasNode
        @emitChange()

      when 'wantsEditEntity'
        @setEditEntity data.id
        @emitChange()

      when 'didBeginEditEntity'
        {entity} = data
        @populateEditor()
        @emitChange()

      when 'cancelEditEntity'
        @setEditEntity null
        @emitChange()

      when 'wantsLoadSoundFile'
        if @data.activeEntityId?
          reader = new FileReader()
          reader.onload = (evt) =>
            @loadSoundBuffer evt
            @emitChange()
          reader.readAsArrayBuffer data.file


  setupCanvas: (canvas) ->
    @paper = new Paper.PaperScope()
    @paper.setup canvas
    canvas.style.backgroundColor = '#ED4F4F'
    @data.paper = @paper

    scrubberRect = new @paper.Rectangle
      from: [@paper.view.bounds.left
             @paper.view.bounds.bottom - @paper.view.viewSize.height * 0.2]
      to: @paper.view.bounds.bottomRight

    scrubber = new @paper.Path.Rectangle scrubberRect
    scrubber.fillColor = 'black'
    scrubber.opacity = 0.2

    canvas.addEventListener 'mousewheel', (evt) =>
      evt.stopPropagation()
      evt.preventDefault()

      pt = @paper.view.viewToProject [evt.offsetX, evt.offsetY]
      synth = @data.activeEntity.synth
      if (scrubber.hitTest pt)?
        nudgeAmount = evt.deltaX / 100
        newValue = synth.options.granular.center + nudgeAmount
        newValue = (newValue + 1) % 1

        @dispatch 'setSynthParameter',
          synth: synth
          parameter:
            name: 'center'
            value: newValue
      else
        nudgeAmountX = evt.deltaX / 100
        nudgeAmountY = evt.deltaY / 100

        newDurationValue =
          synth.options.granular.grainDuration + nudgeAmountX
        newDurationValue = Math.max 0, (Math.min 1, newDurationValue)
        newDeviationValue =
          synth.options.granular.durationRandom + nudgeAmountY
        newDeviationValue = Math.max 0, (Math.min 1, newDeviationValue)

        @dispatch 'setSynthParameter',
          synth: synth
          parameter:
            name: 'grainDuration'
            value: newDurationValue
        @dispatch 'setSynthParameter',
          synth: synth
          parameter:
            name: 'durationRandom'
            value: newDeviationValue

    @controlsLayer = new @paper.Layer
      children: [scrubber]
      name: 'controls'
    @activeEntityLayer = new @paper.Layer {name: 'activeEntity'}

    @paper.view.draw()

    tool = new @paper.Tool()
    tool.on 'mousedown', () ->
      console.log 'inspector mouse down'


  setEditEntity: (entityId) ->
    @data.activeEntityId = entityId
    @data.activeEntity = WorldStore.getEntity @data.activeEntityId

    @activeEntityLayer.removeChildren()


  populateEditor: () ->
    if @data.activeEntity?
      # @paper.view.zoom = @data.activeEntity.path.view.zoom
      shadowCopy = @data.activeEntity.shadow.copyTo @activeEntityLayer
      copy = @data.activeEntity.path.copyTo @activeEntityLayer
      copy.strokeColor = null

      offset =
        @data.activeEntity.path.position.subtract @data.activeEntity.path.view.center

      @activeEntityLayer.scale @data.activeEntity.path.view.zoom

      delta = @paper.view.center.subtract copy.position
      delta = delta.add (offset.multiply @data.activeEntity.path.view.zoom)

      copy.translate delta
      shadowCopy.translate delta


      @paper.view.draw()


  loadSoundBuffer: (evt) ->
    data = evt.target.result
    k.AudioContext.decodeAudioData data, (buffer) =>
      @dispatch 'loadBufferIntoEntity',
        buffer: buffer
        entity: @data.activeEntity


module.exports = new Editor()