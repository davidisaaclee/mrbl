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
      center: 0.5 # relative to buffer duration
      grainDuration: 300
      durationRandom: 150
      deviation: 150
      gain: 0.7
      fadeRatio: 0.1 # relative to grain duration
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
      # @noteOn 1

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

    do restart


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

    offset: offset
    duration: duration


  _pickGrain: () ->
    if @options.buffer?
      deviation = Math.random() * @options.deviation
      duration = @options.grainDuration
      durationRandom = Math.random() * @options.durationRandom
      duration += durationRandom

      offset: @options.center * @bufferDuration - (duration / 2) + deviation
      duration: duration
    else
      offset: 0
      duration: 0



class GranularSynth
  constructor: (@audioContext, options = {}) ->
    @options = _.defaultsDeep options,
      voices: 3
      granular:
        buffer: null
        center: 0.5
        grainDuration: 300
        durationRandom: 150
        deviation: 150
        fadeRatio: 0.25
        gain: if options.voices? then (1 / options.voices) else 1/3
        detune: 0

    @envelope = new Envelope @audioContext,
      attack: 0
      release: 0

    @voices = [0...@options.voices].map () => @_makeVoice()

    Object.defineProperty this, 'output',
      get: () -> @envelope.output

    Object.defineProperty this, 'bufferDuration',
      get: () -> s2ms @options.granular.buffer?.duration

  noteOn: (velocity) ->
    voiceAmp = 1.0 / @voices.length
    freeVoices = @voices.slice()

    attemptTriggerVoice = () =>
      hd = freeVoices.shift()
      if hd?
        freeMe = () ->
          hd.envelope.removeEventListener 'released', freeMe
          freeVoices.push hd
        hd.envelope.addEventListener 'released', freeMe
        return (do hd._willTriggerGrain voiceAmp).duration
      else
        return -1

    triggerAndWait = () =>
      duration = do attemptTriggerVoice
      waitTilNext =
        if duration is -1
        then @options.grainDuration / @voices.length
        else duration / @voices.length
      @_noteTimeout = setTimeout triggerAndWait, waitTilNext
    triggerAndWait()
    @envelope.noteOn velocity

  noteOff: () ->
    if @_noteTimeout
      clearTimeout @_noteTimeout

    @voices.forEach (voice) -> voice.noteOff()
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
    if options.voices?
      while @voices.length isnt options.voices
        if @voices.length > options.voices
          @voices[@voices.length - 1].noteOff()
          @voices.splice (@voices.length - 1), 1
        else if @voices.length < options.voices
          @voices.push @_makeVoice()


    @options = _.assign @options, options
    granularOptions = _.assign @options.granular, options.granular
    @options.granular = granularOptions
    @voices.forEach (voice) => voice.set options.granular

  _makeVoice: () ->
    s = new GranularVoice @audioContext, @options.granular
    s.output.connect @envelope.input
    return s

module.exports = GranularSynth