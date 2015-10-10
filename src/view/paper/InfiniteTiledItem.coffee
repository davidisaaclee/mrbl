_ = require 'lodash'
Paper = require 'paper'

class InfiniteTiledItem extends Paper.Group
  constructor: (@paper, baseItem, options = {}) ->
    super []

    @_options = _.defaults options,
      viewBounds: @paper.view.bounds
      origin: new @paper.Point 0, 0
      overlap: new @paper.Point 0, 0

    @_symbol = new @paper.Symbol baseItem

  setOrigin: (pt) ->
    @_options.origin = pt
    @_updateInstances()

  # Sets the new viewport bounds, and rearranges instances to fill that bounds.
  setViewBounds: (newBounds) ->
    @_options.viewBounds = newBounds
    @_updateInstances()

  _updateInstances: () ->
    @removeChildren()

    symbolSize = @_symbol.definition.bounds.size

    dimWithOverlap =
      width: symbolSize.width * (1 + @_options.overlap.x)
      height: symbolSize.height * (1 + @_options.overlap.y)
    tileRangeX =
      left: Math.floor((@_options.viewBounds.left - @_options.origin.x) / dimWithOverlap.width)
      right: Math.ceil((@_options.viewBounds.right - @_options.origin.x) / dimWithOverlap.width)
    tileRangeY =
      top: Math.floor((@_options.viewBounds.top - @_options.origin.y) / dimWithOverlap.height)
      bottom: Math.ceil((@_options.viewBounds.bottom - @_options.origin.y) / dimWithOverlap.height)


    for x in [tileRangeX.left..tileRangeX.right]
      for y in [tileRangeY.top..tileRangeY.bottom]
        position = new @paper.Point \
          x * dimWithOverlap.width + @_options.origin.x,
          y * dimWithOverlap.height + @_options.origin.y
        @addChild (@_symbol.place position, true)


module.exports = InfiniteTiledItem