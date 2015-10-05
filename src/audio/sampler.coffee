_ = require 'lodash'
EventTarget = require 'oo-eventtarget'

ms2s = (ms) -> ms / 1000.0
s2ms = (s) -> s * 1000.0

class Sampler
  @__instanceCount: 0

  constructor: (@context, @buffer, @offset = 0) ->
    EventTarget this
    @id = Sampler.__instanceCount++
    @velocityNode = @context.createGain()

    Object.defineProperty this, 'output',
      get: () -> @velocityNode

  noteOn: (velocity) ->
    if @node?
      @node.stop()
      @node = null

    @velocityNode.gain.value = Math.max (Math.min 1, velocity), 0

    if @buffer?
      @node = @_makeNode @buffer
      @node.detune.setValueAtTime @detuneAmount, @context.currentTime
      @node.start 0, ms2s @offset
      @node.connect @velocityNode

  noteOff: () ->
    # do nothing

  setOffset: (offset) ->
    @offset = Math.max 0, offset

  detune: (@detuneAmount) ->

  _makeNode: (buffer) ->
    if @node?
      @node.disconnect()

    node = @context.createBufferSource()
    node.buffer = buffer
    # node.connect @gainNode
    return node


module.exports = Sampler