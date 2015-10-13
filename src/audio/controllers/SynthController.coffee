Transformer = require '../../util/Transformer'

dispatcher = require '../../Dispatcher'
Dispatchable = require '../../util/dispatchable'

class SynthController extends Transformer
  constructor: (@synth) ->
    super()
    Dispatchable this, dispatcher

  _setSynthParam: (name, value) ->
    @dispatch 'setSynthParameter',
      synth: @synth
      parameter:
        name: name
        value: value


module.exports = SynthController