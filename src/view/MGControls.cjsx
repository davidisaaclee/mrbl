React = require 'react'
Fader = require './Fader'
Dispatchable = require '../util/Dispatchable'
dispatcher = require '../Dispatcher'

EditorStore = require '../stores/Editor'

MGControls = React.createClass
  displayName: 'MGControls'

  componentDidMount: () ->
    Dispatchable this, dispatcher

  getInitialState: () ->
    editor: EditorStore.getAll()

  render: () ->
    <div className="mg-controls">
      {switch @state.mode
        when 'choose-file'
          @_renderChooseFile()
        else
          @_renderParameters()
      }
    </div>

  _renderChooseFile: () ->
    <div className="filedrop"
         onDragOver={@handleDragover}
         onDrop={@handleDrop}>
      <span>Drop files here.</span>
    </div>

  _renderParameters: () ->
    <div className="faders">
      {if @props.parameters?
        @props.parameters.map (param) =>
          <Fader key={param.id}
                 displayName={param.display}
                 handleInput={@handleParamChange param}/>}
    </div>

  handleDragover: (evt) ->
    evt.stopPropagation()
    evt.preventDefault()
    evt.dataTransfer.dropEffect = 'copy'

  handleDrop: (evt) ->
    evt.stopPropagation()
    evt.preventDefault()

    file = evt.dataTransfer.files[0]
    if file?
      @dispatch 'wantsLoadSoundFile',
        file: file

  handleParamChange: (paramData) -> (evt) =>
    range = paramData.range[1] - paramData.range[0]
    scaled = (evt.target.value / 100.0) * range + paramData.range[0]

    @props.actionCreator.setParameter @props.id,
      id: paramData.id
      value: scaled

module.exports = MGControls
