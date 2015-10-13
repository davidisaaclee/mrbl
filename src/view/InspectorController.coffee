_ = require 'lodash'

Dispatchable = require '../util/dispatchable'
dispatcher = require '../Dispatcher'
EditorStore = require '../stores/Editor'
SynthStore = require '../stores/Synths'

RedInspector = require './inspectors/RedInspector'
BlueInspector = require './inspectors/BlueInspector'

scale = (inLow, inHigh, outLow, outHigh) -> (v) ->
  ((v - inLow) / (inHigh - inLow)) * (outHigh - outLow) + outLow

clamp = (min, max, normalize = false) -> (v) ->
  r = Math.min max, (Math.max min, v)
  if normalize
  then (scale min, max, 0, 1) r
  else r


class InspectorController
  constructor: () ->
    Dispatchable this, dispatcher
    @activeInspector = null

  attach: (paper) ->
    @_paper = paper

    @setupView @_paper

    EditorStore.addChangeListener @_onChange
    do @_onChange

  detach: () ->
    EditorStore.removeChangeListener @_onChange

  update: (state) ->
    if state.editor.events.wantsEdit
      if state.editor.queuedEntity?
        # this should be dynamic in future versions
        entity = state.editor.queuedEntity

        s = entity.synth.controller

        @activeInspector = entity.spawnInspector @_paper
        # @activeInspector = new RedInspector @_paper,
        #   (@_paper.view.bounds.size.multiply 0.8),
        #   () ->
        #     'scrubberHeight': (scale 0, 1, 0.2, 0.8) (s.get 'agitation')
        #     'playheadPosition': entity.synth.options.granular.center
        #     'itemAgitation': 0
        #     'backgroundHue': do ->
        #       v = entity.synth.options.granular.detune
        #       ((scale -1200, 1200, 0, 128) ((clamp -1200, 1200) v))
        #     'backgroundLightness': do ->
        #       v = entity.synth.options.granular.detune
        #       ((scale -1200, 1200, 0.2, 1) ((clamp -1200, 1200) v))
        #     'entityRotation': entity.synth.options.granular.center * 360
        #     'entity':
        #       avatar: entity.paper.avatar

        @activeInspector.addEventListener 'scrubber.drag', (evt) =>
          oldValue = entity.synth.options.granular.center
          newValue = evt.data.delta.x
          newValue = (scale 0, 1000, 0, 1) newValue
          newValue = oldValue + newValue
          newValue = (newValue + 1) % 1
          @dispatch 'setSynthParameter',
            synth: entity.synth
            parameter:
              name: 'center'
              value: newValue
          @activeInspector.dirty()

        # @activeInspector.addEventListener 'background.drag', (evt) =>
        #   oldValue = s.get 'agitation'
        #   newValue = (clamp -1, 1) (evt.data.delta.x / 100)
        #   newValue += oldValue
        #   newValue = (clamp 0, 1) newValue
        #   s.set 'agitation', newValue
        #   @activeInspector.dirty()

        @showInspector @_paper, @_inspectorGroup, @activeInspector
        @dispatch 'didBeginEditEntity',
          entity: state.editor.queuedEntity
      else
        console.error 'wanted edit but no entity queued for edit'

    if state.editor.events.wantsCancel
      SynthStore.removeChangeListener () => @activeInspector.dirty()
      @hideInspector @_paper, @_inspectorGroup, @activeInspector
      @dispatch 'didCancelEditEntity'


  setupView: (paper) ->
    paper.view.element.addEventListener 'mousedown', (evt) =>
      pt = new paper.Point evt.offsetX, evt.offsetY

      if not (@_inspectorGroup.hitTest pt)?
        @dispatch 'wantsCancelEditEntity'

    @_inspectorGroup = new paper.Group
      name: 'inspector'
      # inspector shouldn't worry about external transforms
      transformContent: false

    paper.view.draw()


  showInspector: (paper, inspectorGroup, inspectorModel) ->
    updateInspector = () => inspectorModel.dirty()
    SynthStore.addChangeListener updateInspector
    @_unsubscribeInspector = () ->
      SynthStore.removeChangeListener updateInspector

    inspectorGroup.addChild inspectorModel.paperItem
    inspectorGroup.position = paper.view.center
    inspectorGroup.visible = true

    paper.view.draw()


  hideInspector: (paper, inspectorGroup, inspectorModel) ->
    if @_unsubscribeInspector?
      do @_unsubscribeInspector
      @_unsubscribeInspector = null

    inspectorGroup.visible = false
    inspectorModel?.remove()


  # _setupSynthMapping: (inspectorModel) ->
  #   synth = inspectorModel.entity.synth

  #   dispatchParameterChange = (paramName, value) =>
  #     @dispatch 'setSynthParameter',
  #       synth: synth
  #       parameter:
  #         name: paramName
  #         value: value

  #   makeGetFn = (paramName, transform = _.identity) ->
  #     () -> transform synth.options.granular[paramName]
  #   makeSetFn = (paramName, transform = _.identity) ->
  #     (v) -> dispatchParameterChange paramName, transform v

  #   inspectorModel.mapParameter 'scrubberX',
  #     (makeGetFn 'center', (v) -> v * 10),
  #     (makeSetFn 'center', ((v) ->
  #       cooked = ((v / 10) + 2) % 1

  #       inspectorModel.setFeedbackParameter 'playheadPosition', cooked
  #       return cooked))

  #   inspectorModel.mapParameter 'backgroundX',
  #     (makeGetFn 'grainDuration', (v) -> v / 10),
  #     (makeSetFn 'grainDuration', (v) ->
  #       v_ = v * 10

  #       # in ms
  #       min = 100
  #       max = 1000

  #       cooked = Math.min max, (Math.max min, v_)
  #       normalized = (cooked - min) / (max - min)
  #       inspectorModel.setFeedbackParameter 'scrubberHeight', normalized

  #       return cooked)

  #   inspectorModel.mapParameter 'backgroundY',
  #     (makeGetFn 'detune', ((v) -> v / 50)),
  #     (makeSetFn 'detune', ((v) ->
  #       cooked = v * 50
  #       min = -1200
  #       max = 1200
  #       ranged = (Math.max min, (Math.min max, cooked))
  #       normalized = (ranged - min) / (max - min)
  #       # inspectorModel.setFeedbackParameter 'itemAgitation', normalized
  #       inspectorModel.setFeedbackParameter 'hue', normalized / 3
  #       inspectorModel.setFeedbackParameter 'lightness', normalized
  #       console.log normalized
  #       return cooked))

  #   initialScrubberHeight =
  #     (synth.options.granular.grainDuration - 100) / (1000 - 100)
  #   inspectorModel.setFeedbackParameter \
  #     'scrubberHeight',
  #     initialScrubberHeight

  _fetchState: () ->
    editor: EditorStore.getAll()


  _onChange: () =>
    @state = @_fetchState()
    @update @state


module.exports = InspectorController