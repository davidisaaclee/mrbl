_ = require 'lodash'
EventTarget = require 'oo-eventtarget'

ms2s = (ms) -> ms / 1000.0

class Envelope
  constructor: (@audioContext, envelope = {}) ->
    EventTarget this
    @envelope = _.defaults envelope,
      attack: 100
      release: 1000
    @gainNode = @audioContext.createGain()

    # convenience property for AudioContext.currentTime
    Object.defineProperty this, '_now',
      get: () -> @audioContext.currentTime

    Object.defineProperty this, 'input',
      get: () -> @gainNode

    Object.defineProperty this, 'output',
      get: () -> @gainNode

  setEnvelope: (envelope) ->
    _.assign @envelope, envelope

  noteOn: (velocity) ->
    @_reset()
    @_attack()

  noteOff: () ->
    @_release()

  _attack: () =>
    @gainNode.gain.linearRampToValueAtTime 0.0, @_now
    @gainNode.gain.linearRampToValueAtTime 1.0, @_now + ms2s @envelope.attack

  _release: () =>
    @gainNode.gain.linearRampToValueAtTime 0.0, @_now + ms2s @envelope.release
    @_releaseTimeout = setTimeout (@_willFire 'released'), @envelope.release

  _reset: () ->
    if @_releaseTimeout?
      clearTimeout @_releaseTimeout
      @_releaseTimeout = null
    @gainNode.gain.cancelScheduledValues @_now

  _willFire: (eventName, detail = {}) -> () =>
    @dispatchEvent eventName, detail


class TriggerEnvelope extends Envelope
  constructor: (@audioContext, envelope = {}) ->
    super @audioContext, envelope

    @envelope = _.defaults @envelope,
      hold: 1000

  setHoldDuration: (duration) ->
    @envelope.hold = duration

  noteOn: (velocity) ->
    super velocity

    @_holdTimeout = setTimeout @_release, @envelope.hold + @envelope.attack

  _reset: () ->
    super()

    if @_holdTimeout?
      clearTimeout @_holdTimeout
      @_holdTimeout = null



  noteOff: () ->
    # do nothing




module.exports =
  Envelope: Envelope
  TriggerEnvelope: TriggerEnvelope