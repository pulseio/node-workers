fork = require('child_process').fork
path = require 'path'
workerPath = path.join(__dirname, '../lib/worker.js')
assert = should = require 'should'

spawnWorker = (worker, options) ->
  fork(workerPath, [path.join(__dirname, 'fixtures', worker), JSON.stringify(options)])


describe 'Worker', ->
  
  afterEach ->
    if @worker
      @worker.kill()

  it 'should require coffee script if requested', ->
    @worker = spawnWorker('good_worker.coffee', {coffee: true})
    assert true

  it 'should exit when it receives a disconnect message', (done) ->
    @worker = spawnWorker('good_worker.coffee', {coffee: true})
    @worker.on 'exit', ->
      assert true
      done()
    @worker.disconnect()
    
  it 'should process message when it receives a task message', (done) ->
    @worker = spawnWorker('good_worker.coffee', {coffee: true})
    @worker.on 'message', (msg) ->
      if msg.name == 'processing'
        assert true
        done()
    @worker.send {name: 'task', payload: 'work'}
  
  it 'should send an error message when it catches an error', (done) ->
    @worker = spawnWorker('bad_worker.coffee', {coffee: true})
    @worker.on 'message', (msg) ->
      if msg.name == 'error'
        msg.payload.msg.should.match /Uh oh!/
        done()
    @worker.send {name: 'task', payload: 'work'}
