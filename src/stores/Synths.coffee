Store = require './Store'
SynthPool = require '../audio/SynthPool'
k = require '../Constants'

class Synths extends Store
  constructor: () ->
    super arguments...

    @synthPool = new SynthPool
      voices: 3
    @synthPool.output.connect k.AudioContext.destination

  getDefaultData: () ->
    synthOptions: {}

  delegate: (payload) ->
    data = payload?.action?.data

    switch payload?.action?.actionType
      when 'didMakeEntity'
        {entity} = data
        entity.synth =
          options: @defaultSynthOptions()
        Object.defineProperty entity.synth, 'needsFile',
          get: () -> not entity.synth.options.granular.buffer?

      when 'loadBufferIntoEntity'
        {buffer, entity} = data
        # if not @data.synthOptions[entityId]?
        #   @data.synthOptions[entityId] = @defaultSynthOptions()
        if not entity.synth?
          console.log 'entity has no synth', entity
          debugger

        @loadBuffer buffer, entityId
        entity.synth.needsFile = false

        @emitChange()

        @activateSynth entityId

      when 'didUpdateNearestEntities'
        # data :: [{entity, distance, viewDistanceRatio}]
        cooked = data.map ({entity, distance, viewDistanceRatio}) ->
          id: entity.entityId
          level: (0.5 - viewDistanceRatio) * 2.0

        @setLevels cooked

  defaultSynthOptions: () ->
    voices: 4
    granular:
      buffer: null
      center: 0.5
      grainDuration: 0.1
      durationRandom: 0.1
      deviation: 0.1
      fadeRatio: 0.3
      gain: 0.25
      detune: 0

  loadBuffer: (buffer, id) ->
    @data.synthOptions[id].granular.buffer = buffer

  activateSynth: (id) ->
    opts = @data.synthOptions[id]
    if opts?
      @synthPool.prioritize 1, id, opts

  setLevels: (levelsInfo) ->
    levelsInfo.forEach ({id, level}) =>
      synthOpts = @data.synthOptions[id]
      if synthOpts?
        @synthPool.prioritize level, id, synthOpts
        @synthPool.setGain id, level


module.exports = new Synths()