Pool = require '../lib/pool'
path = require 'path'
assert = should = require 'should'

describe 'Pool', ->

  beforeEach ->
    @pool = new Pool(path.join(__dirname, 'fixtures', 'good_worker.coffee'), {coffee: true, workers: 3})
    
  afterEach ->
    @pool.shutdown()

  describe 'empty', ->
    it 'should emit empty when all workers are done', (done) ->
      @pool.on 'empty', ->
        assert true
        done()
      @pool.push('do something')
  
  describe 'push', ->
    it 'should spawn a worker', ->
      @pool.push('something')
      @pool.workers.length.should.eql 1
      
    describe 'with available workers', ->
      beforeEach (done) ->
        @pool.on 'empty', =>
          @pool.push('something else')        
          done()          
        @pool.push('something')
        
      it 'should not spawn a worker', ->
        @pool.workers.length.should.eql 1
        
      it 'should assign task to available worker', ->
        @pool.available.length.should.eql 0        

    it 'should not exceed available pool of workers', ->
      for i in [0...4]
        @pool.push('task')
      @pool.workers.length.should.eql 3
      @pool.queue.length.should.eql 1
    
  describe 'error', ->
    beforeEach ->
      @errors = errors = []
      @pool = new Pool path.join(__dirname, 'fixtures', 'bad_worker.coffee'),
        {
          coffee: true,
          workers: 1,
          error: (e) ->
            errors.push(e)
        }
        
    afterEach ->
      @pool.shutdown()
      
    it 'should pass error to error handler if available', (done) ->
      @pool.on 'empty', =>
        @errors.length.should.eql 1
        done()
      @pool.push 'task'
        
  describe 'shutdown', ->
    
    beforeEach ->
      @pool.push 'task'
      @pool.shutdown()
      
    it 'should disconnect workers', ->
      for w in @pool.workers
        assert not w.connected
      