_ = require 'lodash'
React = require 'react'

Sampler = require './audio/sampler'
{Envelope, TriggerEnvelope} = require './audio/envelope'
GranularSynth = require './audio/granular'

MGControls = require './view/MGControls'
MGApp = require './view/MGApp'

dispatcher = require './Dispatcher'
world = require './stores/World'
require './stores/Synths'

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




class App
  constructor: (initialState = {}, @dispatcher, view) ->
    @state = _.defaultsDeep initialState,
      world:
        entities: {}
      user:
        editingEntity: null

    view.render @state, dispatcher

class MainView
  constructor: (@container, @rootElement, @stateToParameters) ->
    if not @stateToParameters?
      @stateToParameters = (state, dispatcher) ->
        state: state
        dispatcher: dispatcher

  render: (state, dispatcher) ->
    props = @stateToParameters state, dispatcher
    React.render \
      (React.createElement @rootElement, props),
      @container

# dispatcher.register 'MGField', new MGFieldDelegate()

container = document.getElementById 'container'
view = new MainView container, MGApp
app = new App null, dispatcher, view