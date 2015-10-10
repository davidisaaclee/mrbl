_ = require 'lodash'
React = require 'react'

dispatcher = require '../Dispatcher'
Dispatchable = require '../util/Dispatchable'

VolumeControl = React.createClass
  displayName: 'VolumeControl'

  getInitialState: () ->
    muted: false

  componentDidMount: () ->
    Dispatchable this, dispatcher

  render: () ->
    <div className={@props.className}
         id={@props.id}
         onClick={() =>
          @dispatch 'didMasterChangeMute',
            isMuted: not @state.muted
          @setState {muted: not @state.muted}}>
      <span>click to {if @state.muted then 'unmute' else 'mute'}</span>
    </div>


module.exports = VolumeControl