Parameter = require './Parameter'

# Describes a class which offers an interface via `Parameter`s.
class ParameterizedInterface
  ###
  @param defaultParameters [{<parameterName>: <defaultValue>}]
  ###
  constructor: (defaultParameters) ->
    @_parameters = {}

    for name, value of @defaultParameters
      @_parameters[name] = new Parameter name, value


  getAllParameterValues: () ->
    _.mapValues @_parameters, (p, name) =>
      @getParameter name

  setAllParameterValues: (values) ->
    for name, value of values
      @setParameter name, value

  getParameter: (name) ->
    @_parameters[name]?.get()

  setParameter: (name, value) ->
    @_parameters[name]?.set value

  subscribeParameter: (name, callback, options) ->
    @_parameters[name]?.subscribe callback, options