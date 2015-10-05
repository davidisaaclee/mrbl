AudioContext = window.AudioContext || window.webkitAudioContext

module.exports =
  AudioContext: new AudioContext()