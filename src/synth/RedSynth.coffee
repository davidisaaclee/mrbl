Transformer = require '../util/Transformer'

dispatcher = require '../Dispatcher'
Dispatchable = require '../util/dispatchable'

scale = (inLow, inHigh, outLow, outHigh) -> (v) ->
  ((v - inLow) / (inHigh - inLow)) * (outHigh - outLow) + outLow

clamp = (min, max, normalize = false) -> (v) ->
  r = Math.min max, (Math.max min, v)
  if normalize
  then (scale min, max, 0, 1) r
  else r

class RedSynth extends Transformer
  constructor: (@synth) ->
    Dispatchable this, dispatcher
    super()

    scope = this
    @_registerParameter 'agitation',
      default: 0.1
      set: (value) ->
        grainDuration = value
        grainDuration = (scale 0, 1, 2000, 50) grainDuration

        deviation = value
        deviation = (scale 0, 1, 0, 5000) value

        # fadeRatio = value
        # fadeRatio = 1 - fadeRatio
        # fadeRatio = (scale 0, 1, 0.5, 1) fadeRatio

        scope._setSynthParam 'grainDuration', grainDuration
        scope._setSynthParam 'deviation', deviation
        # scope._setSynthParam 'fadeRatio', fadeRatio

        return value

  _setSynthParam: (name, value) ->
    @dispatch 'setSynthParameter',
      synth: @synth
      parameter:
        name: name
        value: value


module.exports = RedSynth
