_ = require 'lodash'
React = require 'react'

Sampler = require './audio/sampler'
{Envelope, TriggerEnvelope} = require './audio/envelope'
GranularSynth = require './audio/granular'

MGControls = require './view/MGControls'
MGApp = require './view/MGApp'

SynthPool = require './audio/SynthPool'

k = require './Constants'

dispatcher = require './Dispatcher'
world = require './stores/World'
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




class App
  constructor: (initialState = {}, @dispatcher, view) ->
    @state = _.defaultsDeep initialState,
      world:
        entities: {}
      user:
        editingEntity: null

    view.render @state, dispatcher
    @element = view.element

class MainView
  constructor: (@container, @rootElement, @initialProps = {}) ->

  render: (state, dispatcher) ->
    @element = React.createElement @rootElement, @initialProps

    React.render \
      @element,
      @container


sp = new SynthPool
  voices: 3

sp.output.connect k.AudioContext.destination

# dispatcher.register 'MGField', new MGFieldDelegate()

container = document.getElementById 'container'
bcr = container.getBoundingClientRect()

dim =
  width: bcr.width - 80
  height: bcr.height - 80

view = new MainView container, MGApp, dim

app = new App null, dispatcher, view

# canvas.setAttribute 'width', bcr.width - 80
# canvas.setAttribute 'height', bcr.height - 80


# container = document.getElementById 'mg-app'
# canvas = document.getElementById 'mg-field-canvas'
# window.addEventListener 'resize', () ->
#   console.log 'hre'
#   bcr = container.getBoundingClientRect()
#   canvas.setAttribute 'width', bcr.width - 80
#   canvas.setAttribute 'height', bcr.height - 80
#   world.data.paper.scope.view.draw()