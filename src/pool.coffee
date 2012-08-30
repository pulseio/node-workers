fork = require('child_process').fork
path = require 'path'
_ = require 'underscore'
events = require 'events'

module.exports = class Pool extends events.EventEmitter

  constructor: (@file, options = {}) ->

    defaults =
      workers: 10
    @options = _.extend({}, defaults, options)
    
    # Make module path absolute
    unless @file[0] == '/'
      @file = path.join(process.cwd(), @file)
    
    @queue = []
    @workers = []
    @available = []
    @busy = {}
    
  push: (task) ->
    if @available.length > 0
      w = @available.pop()
    else if @workers.length < @options.workers
      @workers.push(w = @fork())      

    if w
      @delegate(w, task)
    else
      @queue.push(task)
      @emit 'full'

  delegate: (worker, task) ->
    worker.send({name: 'task', payload: task})
    @busy[worker.pid] = worker

  findWork: (worker) ->
    if @queue.length > 0
      @delegate(worker, @queue.pop())      
    else
      @available.push(worker)  
      @emit 'empty' if @empty()

  full: ->
    @available.length == 0 and @workers.length == @options.workers
      
  empty: ->
    @available.length == @workers.length

  pending: ->
    @queue.length()
    
  fork: ->
    worker = fork(path.join(__dirname, 'worker.js'), [@file, JSON.stringify({coffee: @options.coffee})])
    
    worker.on 'message', (msg) =>
      switch msg.name
        when 'done' then @findWork(worker)
        when 'error' then @error(worker, msg.payload)
        when 'alive?' then ''
        
    worker.on 'exit', => @exit(worker)
    worker.on 'disconnect', => @exit(worker)
      
  exit: (killed) ->
    delete @busy[killed.pid] if @busy[killed.pid]
    @available = @available.filter (w) -> w.pid != killed.pid
    @workers = @workers.filter (w) -> w.pid != killed.pid
    
  error: (worker, e) ->
    if @options.error?
      @options.error(e)
      @findWork(worker)
    else
      console.log(e)

  shutdown: ->
    for w in @workers when w.connected
      w.disconnect()
