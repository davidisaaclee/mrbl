_ = require 'lodash'

Store = require './Store'
WorldStore = require './World'
# SynthPool = require '../audio/SynthPool'
k = require '../Constants'

DEFAULT_BUFFER = null
do ->
  request = new XMLHttpRequest()
  request.open 'GET', './dist/sounds/hen.wav', true
  request.responseType = 'arraybuffer'
  request.onload = () ->
    k.AudioContext.decodeAudioData request.response, (buffer) =>
      DEFAULT_BUFFER = buffer
  request.send()

class Synths extends Store
  getDefaultData: () ->
    synths: []

  delegate: (payload) ->
    data = payload?.action?.data

    switch payload?.action?.actionType
      when 'didAddEntity'
        {entity} = data
        entity.synth =
          id: entity.id
          level: 0
          options: @defaultSynthOptions()
        Object.defineProperty entity.synth, 'needsFile',
          get: () -> not entity.synth.options.granular.buffer?

      when 'wantsLoadSoundFile'
        {entity, file} = data

        reader = new FileReader()
        reader.onload = (evt) =>
          data = evt.target.result
          k.AudioContext.decodeAudioData data, (buffer) =>
            @dispatch 'loadBufferIntoEntity',
              buffer: buffer
              entity: entity

          @emitChange()
        reader.readAsArrayBuffer data.file

      when 'loadBufferIntoEntity'
        {buffer, entity} = data
        if not entity.synth?
          console.log 'entity has no synth', entity
          debugger

        # for debug mostly
        if not buffer?
          buffer = DEFAULT_BUFFER

        @loadBuffer buffer, entity.synth
        entity.synth.needsFile = false
        @emitChange()

      when 'didUpdateNearestEntities'
        # data :: [{entity, distance, viewDistanceRatio}]
        cooked = data.map ({entity, distance, viewDistanceRatio}) ->
          synth: entity.synth
          level: (0.5 - viewDistanceRatio) * 2.0

        @setLevels cooked
        @emitChange()

      when 'setSynthParameter'
        {synth, parameter} = data
        @setParameter parameter.name, parameter.value, synth
        @emitChange()

  defaultSynthOptions: () ->
    voices: 16
    granular:
      buffer: null
      center: 0.5
      grainDuration: 0.05
      durationRandom: 0.1
      deviation: 0.1
      fadeRatio: 0.3
      gain: 0.25
      detune: 0

  loadBuffer: (buffer, synthData) ->
    synthData.options.granular.buffer = buffer


  setLevels: (levelsInfo) ->
    @data.synths = _ levelsInfo
      .sortBy (a, b) -> a.level - b.level
      .map ({synth, level}) ->
        synth.level = level
        return synth
      .value()

  setParameter: (pName, pValue, synth) ->
    if synth.options.granular[pName]?
      synth.options.granular[pName] = pValue


module.exports = new Synths()