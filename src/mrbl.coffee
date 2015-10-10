_ = require 'lodash'
React = require 'react'

# Sampler = require './audio/sampler'
# {Envelope, TriggerEnvelope} = require './audio/envelope'
# GranularSynth = require './audio/granular'

Application = require './view/Application'
SynthPool = require './audio/SynthPool'

k = require './Constants'

dispatcher = require './Dispatcher'

require './stores/World'
require './stores/Synths'
require './stores/User'

# audioCtx = new (window.AudioContext || window.webkitAudioContext)()

# opts1 =
#   voices: 8
#   granular:
#     buffer: null
#     grainDuration: 0.1
#     deviation: 0.1
#     fadeRatio: 0.3
# synth = new GranularSynth audioCtx
# synth.output.connect audioCtx.destination
# synth.noteOn 1

# url = './dist/sounds/rhodes.wav'

# request = new XMLHttpRequest()
# request.open('GET', url, true)
# request.responseType = 'arraybuffer'

# request.onload = () ->
#   audioCtx.decodeAudioData request.response, (buffer) ->
#     opts.granular.buffer = buffer
#     synth.set opts
#     synth.noteOn 1
#     console.log synth

# request.send()

# loadSoundBuffer = (data) ->
#   audioCtx.decodeAudioData data, (buffer) =>
#     synth.set buffer: buffer
#     synth.noteOn 1


sp = new SynthPool
  voices: 3
sp.output.connect k.AudioContext.destination

container = document.body

# bcr = container.getBoundingClientRect()

audio =
  audioSource: sp.output

initialProps = _.assign {}, audio

view = React.createElement Application, initialProps
React.render view, container