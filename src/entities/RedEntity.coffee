Entity = require './Entity'

RedInspector = require '../view/inspectors/RedInspector'
RedSynth = require '../audio/controllers/RedSynth'

randomColor = require '../view/paper/RandomColor'
makeRandomPath = require '../view/paper/MakeRandomPath'

scale = (inLow, inHigh, outLow, outHigh) -> (v) ->
  ((v - inLow) / (inHigh - inLow)) * (outHigh - outLow) + outLow

clamp = (min, max, normalize = false) -> (v) ->
  r = Math.min max, (Math.max min, v)
  if normalize
  then (scale min, max, 0, 1) r
  else r

class RedEntity extends Entity
  constructor: (id, position) ->
    super id, position

    @synth =
      id: id
      level: 0
      options:
        voices: 8
        granular:
          buffer: null
          center: 0.5
          grainDuration: 1000
          durationRandom: 200
          deviation: 200
          fadeRatio: 0.5
          gain: 0.25
          detune: 0

    @controls = new RedSynth @synth

  spawnAvatar: (paper) ->
    @avatar = @_makeEntityGraphic paper

    return @avatar

  spawnInspector: (paper) ->
    scope = this
    synth = @synth
    controls = @controls
    @inspector = new RedInspector paper,
      (paper.view.bounds.size.multiply 0.8),
      () ->
        'scrubberHeight': (scale 0, 1, 0.2, 0.8) (controls.get 'agitation')
        'playheadPosition': synth.options.granular.center
        'itemAgitation': 0
        'backgroundHue': do ->
          v = synth.options.granular.detune
          ((scale -1200, 1200, 0, 128) ((clamp -1200, 1200) v))
        'backgroundLightness': do ->
          v = synth.options.granular.detune
          ((scale -1200, 1200, 0.2, 1) ((clamp -1200, 1200) v))
        'entityRotation': synth.options.granular.center * 360
        # this should change
        'entity':
          avatar: scope.avatar
    # @inspector = new paper.Path.Rectangle
    #   point: [0, 0]
    #   size: [100, 50]
    #   fillColor: 'red'

    # scope = this

    # paperItem: @inspector
    # addEventListener: () -> console.log 'addEventListener'
    # dirty: () -> console.log 'dirtied'
    # remove: () -> scope.inspector.remove()

  ### DRAWING ###

  _makeEntityGraphic: (paper) ->
    path = @_makePaperEntity paper, @id, @position

    data =
      entityId: @id

    path.data = data
    path.name = @id

    # @_entityGroup.addChild path

    # shadow = @_makeShadow paper, path
    # shadow.data = data
    # shadow.name = @id
    # @_shadowGroup.addChild shadow

    # path: path
    # shadow: shadow

    return path


  _makePaperEntity: (paper, id, position) ->
    if not position?
      position = paper.view.center

    item = makeRandomPath paper,
      left: 0
      top: 0
      width: Math.random() * 450 + 50
      height: Math.random() * 450 + 50
    item.position = position
    item.fillColor =
      gradient:
        stops: [ randomColor {brightness: 0.8}
                 randomColor {brightness: 0.8} ]
      origin: item.bounds.topLeft
      destination: item.bounds.bottomRight

    return item

  _makeShadow: (paper, path) ->
    r = path.clone()
    r.fillColor = 'black'
    r.opacity = 0.6
    r.translate [30, 30]
    return r


module.exports = RedEntity