###
# test for basic
###

## Module dependencies
should = require "should"
mongoose = require 'mongoose'
taggable = require "../mongoose-taggable-via-redis"
redis = require("redis")
async = require "async"

REDIS_CLIENT = redis.createClient()
MODEL_NAME = "Record"

TAGS_NODE = "javascript,server,programming".split(",").sort()
TAGS_JQUERY = "javascript,client,programming".split(",").sort()
TAGS_RAILS = "ruby,programming".split(",").sort()
TAGS_COFFEESCRIPT = "javascript,client,server,programming".split(",").sort()
TAGS_NODE2 = "javascript,server,programming,async,joyent".split(",").sort()

ALL_TAGS = []
ALL_TAGS.push TAGS_NODE, TAGS_JQUERY, TAGS_RAILS, TAGS_COFFEESCRIPT, TAGS_NODE2

# global reference
schema = undefined
Record = null

## Test cases
describe "test basic", ->

  after (done)->
    mongoose.connection.close()
    done()

  # initalize models
  before (done) ->
    console.log "[basic_test::before 1]"

    mongoose.connect "mongodb://localhost/test"
    mongoose.connection.once "connected", (err)->
      return done(err) if err?

      schema = new mongoose.Schema({},
        versionKey: false
      )

      schema.add
        _id: String
        name: String
        createdAt: Date
        owner : String

      schema.plugin taggable,
        taggable : "book"
        redisClient : REDIS_CLIENT
        getScope : -> "owner/#{@owner}" # wich scope

      mongoose.model MODEL_NAME, schema

      done()


  # clean prev test data
  before (done) ->
    console.log "[basic_test::before 2]"
    Record = mongoose.model(MODEL_NAME)
    Record.remove done
    return

  # initialize test data
  before (done) ->
    console.log "[basic_test::before 3]"
    arr = []
    for i in [0...100]
      arr.push i

    async.each arr, ((i, cb) ->
      obj =
        _id: "#{(Date.now()).toString(36)}#{i}"
        name: "paginate_" + i
        owner : 'tester'
        createdAt: new Date().setDate(new Date().getDate() - i)

      Record(obj).save cb
      return
    ), done
    return

  before (done) ->
    REDIS_CLIENT.flushall()
    setTimeout done, 1800
    return

  describe "mongoose-taggable-via-redis", ->

    it "should able to set tags", (done)->
      Record.findOne (err, item)->
        should.not.exist err
        item.setTags TAGS_NODE, (err)->
          should.not.exist err
          Record.findWithTags {_id:item.id}, (err, results)->
            should.not.exist err
            results.length.should.eql 1
            tags = results[0].tags
            console.log "[basic_test] tags:#{tags}"
            tags.sort().should.containDeep(TAGS_NODE)

            Record.where({_id:item.id}).execWithTag (err, results2)->
              should.not.exist err
              results2.length.should.eql 1
              tags = results2[0].tags
              tags.sort().should.containDeep(TAGS_NODE)
              done()
          return
        return
      return

    it "set more tags", (done)->
      Record.where().limit(10).exec (err, results)->
        should.not.exist err
        async.each results, ((item, cb) ->
          item.setTags(ALL_TAGS[ALL_TAGS.length * Math.random() >>> 0], cb)
          return
        ), done

    it "popularTags", (done)->
      Record.popularTags 10, (err, tags)->
        console.dir tags
        should.not.exist err
        tags.length.should.above TAGS_NODE.length
        done()

    it "findByTags", (done)->
      Record.findByTags "programming", (err, results)->
        console.dir results
        should.not.exist err
        results.length.should.above 1
        for result in results
          console.log "[basic_test] id:#{result.id}, tags:#{result.tags}"
        done()
        return
      return





