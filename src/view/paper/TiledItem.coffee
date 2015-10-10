_ = require 'lodash'

module.exports = makeTiledItem = (paper, baseItem, options = {}) ->
  options = _.defaults options,
    position: baseItem.position
    widthInTiles: 5
    heightInTiles: 5
    removeOriginal: false
    onInstance: _.identity
    group: new paper.Group()

  if not options.random?
    options.random = {}
  options.random = _.defaults options.random,
    x: 0
    y: 0

  symbol = new paper.Symbol baseItem

  if options.removeOriginal
    do baseItem.remove


  for x in [0...options.widthInTiles]
    for y in [0...options.heightInTiles]
      instance = do symbol.place
      offset = new paper.Point \
        symbol.definition.bounds.width * x,
        symbol.definition.bounds.height * y
      offset = offset.add [Math.random() * (options.random.x * 2) - options.random.x,
                           Math.random() * (options.random.y * 2) - options.random.y]
      instance.position = options.position.add offset

      instance = options.onInstance instance
      options.group.addChild instance

  return options.group