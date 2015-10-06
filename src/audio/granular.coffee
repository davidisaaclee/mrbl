_ = require 'lodash'
require 'object.observe'

TimeoutManager = require '../util/TimeoutManager'

Sampler = require './sampler'
{Envelope, TriggerEnvelope} = require './envelope'

ms2s = (ms) -> ms / 1000.0
s2ms = (s) -> s * 1000.0

class GranularVoice
  constructor: (@audioContext, options = {}) ->
    @options = _.defaults options,
      buffer: null
      center: 0.5
      grainDuration: 0.1
      durationRandom: 0.1
      deviation: 0.1
      gain: 0.7
      fadeRatio: 0.1
      detune: 0

    @sampler = new Sampler @audioContext, @options.buffer
    @envelope = new TriggerEnvelope @audioContext

    @sampler.output.connect @envelope.input

    Object.defineProperty this, 'output',
      get: () -> @envelope.output

    Object.defineProperty this, 'bufferDuration',
      get: () -> s2ms @options.buffer.duration

  set: (options = {}) ->
    if options.buffer? and options.buffer isnt @sampler.buffer
      @noteOff()
      @sampler.noteOff()
      @sampler.output.disconnect()
      @sampler = new Sampler @audioContext, @options.buffer
      @sampler.output.connect @envelope.input
      @noteOn 1

    @options = _.assign @options, options


  # setBuffer: (@buffer) ->
  #   @noteOff()

  #   @sampler.noteOff()
  #   @sampler.output.disconnect()

  #   @sampler = new Sampler @audioContext, @buffer
  #   @sampler.output.connect @envelope.input

  noteOn: (velocity) ->
    restart = @_willTriggerGrain velocity
    @envelope.addEventListener 'released', restart

    @_unsubRelease = () =>
      @envelope.removeEventListener 'released', restart

    do @_willTriggerGrain velocity


  noteOff: () ->
    if @_unsubRelease?
      @_unsubRelease()
      @_unsubRelease = null

    @sampler.noteOff()
    @envelope.noteOff()


  _willTriggerGrain: (velocity) -> () =>
    {offset, duration} = @_pickGrain()

    fadeTime = @options.fadeRatio * duration
    @envelope.setEnvelope
      attack: fadeTime
      hold: duration - fadeTime * 2
      release: fadeTime

    @sampler.setOffset offset
    @sampler.detune @options.detune

    @sampler.noteOn velocity
    @envelope.noteOn velocity


  _pickGrain: () ->
    # maxDuration = @bufferDuration
    maxDuration = 3000
    if @options.buffer?
      deviation = Math.random() * @options.deviation * maxDuration
      durationRandom = Math.random() * @options.durationRandom * maxDuration
      duration = @options.grainDuration * maxDuration + durationRandom

      offset: @options.center * @bufferDuration - (duration / 2) + deviation
      duration: duration
    else
      offset: 0
      duration: 0



class GranularSynth
  constructor: (audioContext, options = {}) ->
    @options = _.defaultsDeep options,
      voices: 3
      granular:
        buffer: null
        center: 0.5
        grainDuration: 0.1
        durationRandom: 0.1
        deviation: 0.1
        fadeRatio: 0.1
        gain: if options.voices? then (1 / options.voices) else 1/3
        detune: 0

    @envelope = new Envelope audioContext,
      attack: 0
      release: 0

    @voices = [0...@options.voices].map () =>
      s = new GranularVoice audioContext, @options.granular
      s.output.connect @envelope.input
      return s

    @_triggerTimingManager = new TimeoutManager()

    Object.defineProperty this, 'output',
      get: () -> @envelope.output

    Object.defineProperty this, 'bufferDuration',
      get: () -> s2ms @options.granular.buffer?.duration

    # Object.observe @options.granular, () =>
    #   @voices.forEach (voice) => voice.set @options.granular


  noteOn: (velocity) ->
    console.log 'hit it!'

    amp = 1.0 / @voices.length
    dt = amp * @options.granular.grainDuration * @bufferDuration
    @voices.forEach (voice, idx) =>
      @_triggerTimingManager.setTimeout (dt * idx), () ->
        voice.noteOn amp
    @envelope.noteOn velocity

  noteOff: () ->
    @_triggerTimingManager.clearAll()

    @voices.forEach (voice) ->
      voice.noteOff()
    @envelope.noteOff()

  parameters: () ->
    center:
      id: 'center'
      display: 'center'
      range: [0, 1]
      mapValue: (val) =>
        @options.granular.center = val
    grainDuration:
      id: 'grainDuration'
      display: 'grain duration'
      range: [0, 1]
      mapValue: (val) =>
        @options.granular.grainDuration = val
    durationRandom:
      id: 'durationRandom'
      display: 'duration random'
      range: [0, 1]
      mapValue: (val) =>
        @options.granular.durationRandom = val
    deviation:
      id: 'deviation'
      display: 'offset deviation'
      range: [0, 1]
      mapValue: (val) =>
        @options.granular.deviation = val
    fadeRatio:
      id: 'fadeRatio'
      display: 'fade ratio'
      range: [0, 1]
      mapValue: (val) =>
        @options.granular.fadeRatio = val
    detune:
      id: 'detune'
      display: 'detune (cents)'
      range: [-1200, 1200]
      mapValue: (val) =>
        @options.granular.detune = val

  parameterList: () ->
    _.values @parameters()

  set: (options) ->
    # if options.granular.buffer? and options.granular.buffer isnt @options.granular.buffer
    #   @noteOff()

    granularOptions = _.assign @options.granular, options.granular
    @options = _.assign @options, options
    @options.granular = granularOptions
    @voices.forEach (voice) => voice.set options.granular

  # setBuffer: (@buffer) ->
  #   @options = _.defaultsDeep @options,
  #     voices: 3
  #     granular:
  #       center: 0.5
  #       grainDuration: 0.1
  #       durationRandom: 0.1
  #       deviation: 0.1
  #       fadeRatio: 0.1
  #       gain: if @options.voices? then (1 / @options.voices) else 0
  #       detune: 0

  #   @noteOff()
  #   @voices.forEach (voice) =>
  #     voice.setBuffer @buffer

module.exports = GranularSynth