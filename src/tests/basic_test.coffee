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

# global reference
schema = undefined
Record = null

## Test cases
describe "test basic", ->

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

      console.dir taggable

      schema.plugin taggable,
        taggable : "book"
        redisClient : REDIS_CLIENT

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
        createdAt: new Date().setDate(new Date().getDate() - i)

      Record(obj).save cb
      return
    ), done
    return

  describe "mongoose-taggable-via-redis", ->

    it "should able to set tags", (done)->
      Record.findOne (err, item)->
        should.not.exist err
        item.setTags TAGS_NODE, (err)->
          should.not.exist err
          Record.findWithTags {_id:item.id}, (err, results)->
            console.dir results
            should.not.exist err
            results.length.should.eql 1
            tags = results[0].tags
            console.log "[basic_test] tags:#{tags}"
            tags.sort().should.containDeep(TAGS_NODE)
            done()
          return
        return
      return

    return



