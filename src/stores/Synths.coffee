_ = require 'lodash'

Store = require './Store'
WorldStore = require './World'
# SynthPool = require '../audio/SynthPool'
k = require '../Constants'

class Synths extends Store
  getDefaultData: () ->
    synths: []

  delegate: (payload) ->
    data = payload?.action?.data

    switch payload?.action?.actionType
      when 'didAddEntity'
        {entity} = data
        entity.synth =
          id: entity.entityId
          level: 0
          options: @defaultSynthOptions()
        Object.defineProperty entity.synth, 'needsFile',
          get: () -> not entity.synth.options.granular.buffer?

      when 'loadBufferIntoEntity'
        {buffer, entity} = data
        if not entity.synth?
          console.log 'entity has no synth', entity
          debugger

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
    voices: 6
    granular:
      buffer: null
      center: 0.5
      grainDuration: 0.01
      durationRandom: 0.005
      deviation: 0.01
      fadeRatio: 0.5
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