React = require 'react'
MGControls = require './MGControls'
MGField = require './MGField'

WorldStore = require '../stores/World'
EditorStore = require '../stores/Editor'

Dispatchable = require '../util/Dispatchable'
dispatcher = require '../Dispatcher'

MGApp = React.createClass
  displayName: 'MGApp'

  componentDidMount: () ->
    Dispatchable this, dispatcher
    WorldStore.addChangeListener @_onChange
    EditorStore.addChangeListener @_onChange

  componentWillUnmount: () ->
    WorldStore.removeChangeListener @_onChange
    EditorStore.removeChangeListener @_onChange

  getInitialState: () ->
    world: WorldStore.getAll()
    editor: EditorStore.getAll()

  inspectorStyle: () ->
    if not @state.editor.activeEntityId?
    then visibility: 'hidden'
    else {}

  render: () ->
    <div className="mg-app">
      <MGField width={@_screenDimensions().width}
               height={@_screenDimensions().height}
               dispatcher={@props.dispatcher}/>
      <div className="inspector" style={@inspectorStyle()}>
        <MGControls/>
      </div>
    </div>

  _screenDimensions: () ->
    width: Math.max(document.documentElement.clientWidth, window.innerWidth || 0)
    height: Math.max(document.documentElement.clientHeight, window.innerHeight || 0)

  _onChange: () ->
    @setState
      world: WorldStore.getAll()
      editor: EditorStore.getAll()

module.exports = MGApp