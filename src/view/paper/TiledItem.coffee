_ = require 'lodash'

module.exports = makeTiledItem = (paper, baseItem, options = {}) ->
  options = _.defaultsDeep options,
    position: baseItem.position
    widthInTiles: 5
    heightInTiles: 5
    removeOriginal: false
    random:
      x: 0
      y: 0
    onInstance: _.identity
    group: new paper.Group()

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

  if options.layer
    options.layer.addChild options.group

  return options.group
