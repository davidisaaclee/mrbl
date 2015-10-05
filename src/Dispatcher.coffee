Promise = (require 'es6-promise').Promise

class Dispatcher
  constructor: () ->
    @delegates = []

  register: (delegate) ->
    @delegates.push delegate

  dispatch: (payload) ->
    _resolves = []
    _rejects = []
    _promises = @delegates
      .map (d, idx) ->
        new Promise (resolve, reject) ->
          _resolves[idx] = resolve
          _rejects[idx] = reject

    @delegates
      .forEach (delegate, idx) ->
        Promise.resolve (delegate payload)
          .then \
            (() -> _resolves[i] payload),
            (() -> _rejects[i] (new Error 'Dispatcher callback unsuccessful'))

    _promises = []


module.exports = new Dispatcher()