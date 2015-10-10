# TODO

- better structure for synths, entities, and inspectors
  - all three should expose parameters, and make it easy to map among them or
    to external sources

  - Parameter
    - name :: String
    - value :: Number
    - set :: (Number, [clamp :: [Number, Number]], [scale :: [[Number, Number], [Number, Number]]]) -> Number
    - get :: ([unscale :: [Number, Number]]) -> Number

  - ParameterizedInterface
    ParamOptions ::=
      value: Number
      observer: Function
      scale: [Number, Number]
      clamp: [Number, Number]

    - defaultParameters :: {<paramName>: ParamOptions}
    - getAllParametersRaw: () -> {[<paramName>: <raw value>]}
    - setAllParametersRaw: ({[<paramName>: <raw value>]}) -> ()
    - getParameter: (name) -> Number
    - setParameter: (name, value, isRaw = false) -> Number

  - Entity extends ParameterizedInterface
  - Synth extends ParameterizedInterface
  - Inspector extends ParameterizedInterface

  - this is all silly and just FRP, so I should just use RxJS
  - or is it all silly and i should just join the bright-eyed "fuck it ship it" crew

- fix up RedInspector

- fix focusing on items

- supply audio stream to inspector (or on entity)

- pan sounds

- better (more efficient) infinite tiled


# FINISHED

+ change all layers to groups
  - apparently, the only added value for layers is the ability to have an active
    layer, which is unwanted for our graphics system

+ separate inspector and make abstract baseclass
  - it would be nice to easily make different inspectors for different synths
  - baseclass: make it easy to map an inspector to a model

+ fix `didViewportTransform` action
  - moving camera control to the layer instead of the project complicates things.
  - test the new camera control (behavior of adding children after transforming layer)
    - turns out that transforming a "world" layer doesn't affect any children
      added after the transform. i see two solutions:
      - keep this method of transform, and subclass `Layer` to apply its
        transform on any new children
      - maintain another Paper stage for non-world elements
  - add viewport bounds to action

+ visual feedback on inspector
  - add "feedback parameters" to InspectorBase - abstractions to control parts
    of an inspector according to a stream of values

    # Updates the specified parameter, triggers all feedback listeners on that parameter.
    - setFeedbackParameter : (paramName : String, value : Float) -> ()

    # Used internally to register parts of view that change based on feedback parameter
    # Callback : (value : Float, [item : Paper.Item ?]) -> ()
    - _addFeedbackListener : (paramName : String, callback : Callback) -> ()

    # Used internally to get a feedback parameter's value.
    - _getFeedbackParameter : (paramName : String) -> Float

    - need to remove feedback listeners at `remove()`

+ bring back parallax for background

+ infinite background
  - InfiniteTiledItem extends Paper.Group
    - constructor: (baseItem, options) ->

    # Sets the new viewport bounds, and rearranges instances to fill that bounds.
    - setViewBounds: (newBounds) ->
  - currently destroying and instantiating all PlacedSymbols on each viewport
    transform - relatively fast but should definitely change in future

+ fix granular engine to be smoother

+ add master audio controls
  - it would be great if the document could be set up like, nicely at all