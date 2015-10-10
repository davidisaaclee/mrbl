_ = require 'lodash'
k = require '../Constants'

GranularSynth = require './granular'
SynthStore = require '../stores/Synths'

class SynthPool
  constructor: (options = {}) ->
    SynthStore.addChangeListener () =>
      @update SynthStore.getAll()

    @options = _.defaults options,
      voices: 4

    @voices = [0...@options.voices].map (idx) =>
      synth: new GranularSynth k.AudioContext
      # entity: null
      gain: k.AudioContext.createGain()
      index: idx
      id: null
      priority: -1
      busy: () -> @id?

    @output = k.AudioContext.createGain()

    @voices
      .forEach (voice) =>
        voice.synth.output.connect voice.gain
        voice.gain.connect @output

    @update SynthStore.getAll()

  update: (state) ->
    @output.gain.value =
      state.master.volume * (if state.master.isMuted then 0 else 1)

    _ state.synths
      .take @options.voices
      .value()
      .forEach (synth) =>
        v = _.find @voices, (voice) ->
          voice.id is synth.id
        if v?
          @_updateVoice v, synth
        else
          @pushSynth synth, synth.level

  pushSynth: (synth, priority) ->
    bottom = (_.sortBy @voices, 'priority')[0]
    if bottom.priority < priority
      @voices[bottom.index] = _.assign bottom,
        id: synth.id
        priority: priority
      @voices[bottom.index].synth.set synth.options

      # debug
      @noteOn bottom.index, 1
    else
      console.log 'not high enough priority'

  set: (voiceIdx, voiceOptions = {}, synthOptions = {}) ->
    if @voices[voiceIdx]?
      @_setVoice @voices[voiceIdx], voiceOptions, synthOptions


  prioritize: (priority, synth) ->
    inPool = (@voices.filter (v) -> v.id is synth.id)[0]
    if inPool?
      return inPool.priority = priority
    else
      bottom = (_.sortBy @voices, 'priority')[0]
      voiceOptions =
        id: synth.id
        priority: priority
      @_setVoice bottom, voiceOptions, synth.options


  setGain: (gain, synth) ->
    voice = null
    for v in @voices
      if v.id is synth.id
        voice = v
        break
    if voice?
      voice.gain.gain.linearRampToValueAtTime \
        gain,
        k.AudioContext.currentTime + 0.016
    else
      console.log "couldn't find voice"

  noteOn: (voiceIdx, velocity) ->
    @voices[voiceIdx]?.synth?.noteOn velocity

  _updateVoice: (voice, synth) ->
    voice.synth.set synth.options
    voice.gain.gain.linearRampToValueAtTime \
        synth.level,
        k.AudioContext.currentTime + 0.016

  _setVoice: (voice, voiceOptions, synthOptions) ->
    _.assign voice, voiceOptions
    voice.synth.set synthOptions
    # voice.synth.options = synthOptions

    # debug
    @noteOn voice.index, 1


module.exports = SynthPool