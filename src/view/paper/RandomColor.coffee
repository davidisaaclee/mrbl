Paper = require 'paper'
_ = require 'lodash'

module.exports = randomColor = (options = {}, paper = Paper) ->
  options = _.defaults options,
    hue: Math.random() * 360
    saturation: Math.random()
    brightness: Math.random()

  new paper.Color options