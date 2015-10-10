_ = require 'lodash'

Dispatchable = require '../util/dispatchable'
dispatcher = require '../Dispatcher'
EditorStore = require '../stores/Editor'

RedInspector = require './inspectors/RedInspector'

class InspectorController
  constructor: () ->
    Dispatchable this, dispatcher
    @activeInspector = null

  attach: (paper) ->
    @setupView paper

    EditorStore.addChangeListener @_onChange
    do @_onChange

  detach: () ->
    EditorStore.removeChangeListener @_onChange

  update: (state) ->
    if state.editor.events.wantsEdit
      if state.editor.queuedEntity?
        # this should be dynamic in future versions
        @activeInspector = new RedInspector state.editor.queuedEntity

        @showInspector @_paper, @_inspectorGroup, @activeInspector
        @dispatch 'didBeginEditEntity',
          entity: state.editor.queuedEntity
      else
        console.error 'wanted edit but no entity queued for edit'

    if state.editor.events.wantsCancel
      @hideInspector @_paper, @_inspectorGroup, @activeInspector
      @dispatch 'didCancelEditEntity'


  setupView: (paper) ->
    @_paper = paper

    paper.view.element.addEventListener 'mouseup', (evt) =>
      pt = new paper.Point evt.offsetX, evt.offsetY
      if not (paper.project.hitTest pt)?
        @dispatch 'wantsCancelEditEntity'

    @_inspectorGroup = new paper.Group
      name: 'inspector'
    paper.view.draw()


  hideInspector: (paper, inspectorGroup, inspectorModel) ->
    inspectorGroup.visible = false
    inspectorModel?.remove()

  showInspector: (paper, inspectorGroup, inspectorModel) ->
    @_setupSynthMapping inspectorModel

    item = inspectorModel.draw paper, (paper.view.bounds.size.multiply 0.8)
    inspectorGroup.addChild item
    inspectorGroup.position = paper.view.center

    paper.view.draw()


    inspectorGroup.position = paper.view.center
    inspectorGroup.visible = true


  _setupSynthMapping: (inspectorModel) ->
    synth = inspectorModel.entity.synth

    dispatchParameterChange = (paramName, value) =>
      @dispatch 'setSynthParameter',
        synth: synth
        parameter:
          name: paramName
          value: value

    makeGetFn = (paramName, transform = _.identity) ->
      () -> transform synth.options.granular[paramName]
    makeSetFn = (paramName, transform = _.identity) ->
      (v) -> dispatchParameterChange paramName, transform v

    inspectorModel.mapParameter 'scrubberX',
      (makeGetFn 'center', (v) -> v * 10),
      (makeSetFn 'center', ((v) ->
        cooked = ((v / 10) + 2) % 1

        inspectorModel.setFeedbackParameter 'playheadPosition', cooked
        return cooked))

    inspectorModel.mapParameter 'backgroundX',
      (makeGetFn 'grainDuration', (v) -> v / 10),
      (makeSetFn 'grainDuration', (v) ->
        v_ = v * 10

        # in ms
        min = 100
        max = 1000

        cooked = Math.min max, (Math.max min, v_)
        normalized = (cooked - min) / (max - min)
        inspectorModel.setFeedbackParameter 'scrubberHeight', normalized

        return cooked)

    inspectorModel.mapParameter 'backgroundY',
      (makeGetFn 'detune', ((v) -> v / 50)),
      (makeSetFn 'detune', ((v) ->
        cooked = v * 50
        min = -1200
        max = 1200
        ranged = (Math.max min, (Math.min max, cooked))
        normalized = (ranged - min) / (max - min)
        # inspectorModel.setFeedbackParameter 'itemAgitation', normalized
        inspectorModel.setFeedbackParameter 'hue', normalized / 3
        inspectorModel.setFeedbackParameter 'lightness', normalized
        console.log normalized
        return cooked))

    initialScrubberHeight =
      (synth.options.granular.grainDuration - 100) / (1000 - 100)
    inspectorModel.setFeedbackParameter \
      'scrubberHeight',
      initialScrubberHeight

  _fetchState: () ->
    editor: EditorStore.getAll()


  _onChange: () =>
    @state = @_fetchState()
    @update @state


module.exports = InspectorController