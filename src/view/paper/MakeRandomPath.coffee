_ = require 'lodash'

# makeRandomPath = (bounds = {}, maxSegments = 10) ->
#   bounds = _.defaults bounds,
#     left: 0
#     top: 0
#     width: 100
#     height: 100

#   segments = [0...maxSegments]
#     .map (idx) ->
#       [Math.random() * bounds.width + bounds.left,
#        Math.random() * bounds.height + bounds.top]
#     .map (anchor, idx, array) ->
#       l = array.length
#       previous = array[(idx + l - 1) % l]
#       next = array[(l + 1) % l]


#       p2n = new fabric.Point \
#         (next[0] - previous[0]),
#         (next[1] - previous[1])

#       smooth = Math.random()

#       anchor: anchor
#       handleIn: p2n.multiply smooth
#       handleOut: p2n.multiply -smooth

#   # curves = segments.map (segment, idx, array) ->
#   #   if idx is (array.length - 1)
#   #     return
#   #   else
#   #     return new paper.Curve \
#   #       segment,
#   #       array[idx + 1]

#   svgReduction = (acc, elm, idx) ->
#     if idx is 0
#       acc += "M #{elm.anchor[0]} #{elm.anchor[1]}"
#     else
#       acc += " L #{elm.anchor[0]} #{elm.anchor[1]}"
#   svgPathString = segments.reduce svgReduction, ''
#   svgPathString += ' z'

#   console.log svgPathString

#   return new fabric.Path svgPathString

makeRandomPath = (paper, bounds = {}, maxSegments = 10) ->
  bounds = _.defaults bounds,
    left: 0
    top: 0
    width: 100
    height: 100

  segments = [0...maxSegments]
    .map (idx) ->
      [Math.random() * bounds.width + bounds.left,
       Math.random() * bounds.height + bounds.top]
    .map (anchor, idx, array) ->
      l = array.length
      previous = array[(idx + l - 1) % l]
      next = array[(l + 1) % l]

      p2n = new paper.Point \
        (next[0] - previous[0]),
        (next[1] - previous[1])

      smoothFactor = Math.random()

      return new paper.Segment
        point: anchor
        handleIn: p2n.multiply smoothFactor
        handleOut: p2n.multiply -smoothFactor

  curves = segments.map (segment, idx, array) ->
    if idx is (array.length - 1)
      return
    else
      return new paper.Curve \
        segment,
        array[idx + 1]


  return new paper.Path
    segments: segments
    curves: curves
    closed: true


module.exports = makeRandomPath