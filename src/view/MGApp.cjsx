React = require 'react'
MGControls = require './MGControls'
MGInspector = require './MGInspector'
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

    # window.addEventListener 'resize', () => @onResize()
    # do @onResize

    # bcr = @refs.container.getDOMNode().getBoundingClientRect()
    # console.log bcr
    # @refs.field.setProps
    #   width: bcr.width
    #   height: bcr.height

  componentWillUnmount: () ->
    WorldStore.removeChangeListener @_onChange
    EditorStore.removeChangeListener @_onChange

    window.removeEventListener 'resize', () => @onResize()

  getInitialState: () ->
    world: WorldStore.getAll()
    editor: EditorStore.getAll()

  inspectorStyle: () ->
    if not @state.editor.activeEntityId?
    then visibility: 'hidden'
    else {}

  render: () ->
    <div id="mg-app"
         className="mg-app"
         ref="container">
      <MGField width={@props.width}
               height={@props.height}
               style={@_fieldStyle()}
               ref="field"/>
      <MGInspector hidden={not @state.editor.activeEntityId?}/>
    </div>

  # onResize: () ->
  #   bcr = @refs.container.getDOMNode().getBoundingClientRect()
  #   @setProps
  #     width: bcr.width - 80
  #     height: bcr.height - 80

  _fieldStyle: () ->
    zIndex: 0
    backgroundColor: 'black'


  _screenDimensions: () ->
    container = @refs.container
    if container?
      bcr = container.getDOMNode().getBoundingClientRect()
      width: bcr.width
      height: bcr.height
    else
      width: Math.max(document.documentElement.clientWidth, window.innerWidth || 0)
      height: Math.max(document.documentElement.clientHeight, window.innerHeight || 0)
    # width: '100%'
    # height: '100%'

  _onChange: () ->
    @setState
      world: WorldStore.getAll()
      editor: EditorStore.getAll()

module.exports = MGApp