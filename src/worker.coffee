HEARTBEAT = 1000

class Worker
  
  constructor: (file, options = {}) ->

    require('coffee-script') if options.coffee
    @module = require(file)

    process.on 'message', @message
    process.on 'disconnect', @shutdown
    @heartbeat()

  # Send periodic messages to parent to make sure it's still alive
  heartbeat: ->
    setTimeout ->
      try
        process.send {name: 'alive?'}
      catch e
        console.log "Exiting"
        process.exit(0) # Parent died
    , 1000
    
  message: (msg) =>
    switch msg.name
      when 'task' then @perform(msg)

  perform: (task) ->
    
    process.send {name: 'processing'}
    
    try
      @module.work task, (e, result) ->
        if e
          process.send {name: 'error', payload: {msg: e.toString(), stack: e.stack}}
        else
          process.send {name: 'done', payload: result}
    catch e
      process.send {name: 'error', payload: {msg: e.toString(), stack: e.stack}}

  shutdown: =>    
    process.exit(0)

file = process.argv[2]
options = process.argv[3]
options = JSON.parse(options) if options
exports.worker = new Worker(file, options)

