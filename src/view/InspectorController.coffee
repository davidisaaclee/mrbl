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
    dispatchParameterChange = (paramName, value) =>
      @dispatch 'setSynthParameter',
        synth: inspectorModel.entity.synth
        parameter:
          name: paramName
          value: value

    makeGetFn = (paramName) ->
      () -> inspectorModel.entity.synth.options.granular[paramName]
    makeSetFn = (paramName) ->
      (v) ->
        dispatchParameterChange paramName, v

    inspectorModel.mapParameter 'scrubberX',
      (makeGetFn 'center'),
      ((v) -> dispatchParameterChange 'center', ((v + 2) % 1))

    inspectorModel.mapParameter 'backgroundX',
      (makeGetFn 'grainDuration'),
      (makeSetFn 'grainDuration')

    inspectorModel.mapParameter 'backgroundY',
      (makeGetFn 'durationRandom'),
      (makeSetFn 'durationRandom')


  _fetchState: () ->
    editor: EditorStore.getAll()


  _onChange: () =>
    @state = @_fetchState()
    @update @state


module.exports = InspectorController