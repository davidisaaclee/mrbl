_ = require 'lodash'
k = require '../Constants'

GranularSynth = require './granular'

class SynthPool
  constructor: (options = {}) ->
    @options = _.defaults options,
      voices: 4

    @voices = [0...@options.voices].map (idx) =>
      synth: new GranularSynth k.AudioContext
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


  set: (voiceIdx, voiceOptions = {}, synthOptions = {}) ->
    if @voices[voiceIdx]?
      @_setVoice @voices[voiceIdx], voiceOptions, synthOptions


  prioritize: (priority, id, options = {}) ->
    inPool = (@voices.filter (v) -> v.id is id)[0]
    if inPool?
      return inPool.priority = priority
    else
      bottom = (_.sortBy @voices, 'priority')[0]
      voiceOptions =
        id: id
        priority: priority
      @_setVoice bottom, voiceOptions, options


  setGain: (id, gain) ->
    console.log 'setGain', id, gain
    voice = null
    for v in @voices
      if v.id is id
        voice = v
        break
    if voice?
      voice.gain.gain.value = gain
    else
      console.log "couldn't find voice"

  noteOn: (voiceIdx, velocity) ->
    @voices[voiceIdx]?.synth?.noteOn velocity

  _setVoice: (voice, voiceOptions, synthOptions) ->
    _.assign voice, voiceOptions
    voice.synth.set synthOptions

    # debug
    @noteOn voice.index, 1


module.exports = SynthPool