# Rx = require 'rx'

# class ObservableInterface
#   constructor: (defaults) ->
#     @_parameters = {}
#     for name, value of defaults
#       @_parameters[name] = Rx.Just value

#   push: (name, value) ->
#     p = @_parameters[name]
#     if p?
#       sourceStream = Rx.From value