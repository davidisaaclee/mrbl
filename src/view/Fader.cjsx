React = require 'react'

Fader = React.createClass
  ###
  properties:
    min
    max
    mapValue
    name
  ###

  displayName: 'Fader'

  render: () ->
    console.log @props
    <div className="fader">
      <input className="fader-control" type="range" onInput={@props.handleInput}/>
      <div className="label">{@props.displayName}</div>
    </div>


module.exports = Fader