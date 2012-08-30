Pool = require './pool'

exports.pool = (file, options) ->
  new Pool(file, options)