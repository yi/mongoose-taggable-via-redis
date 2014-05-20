###
# test tags removal when db record removed
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
describe "test removal", ->

  # initalize models
  before (done) ->
    console.log "[removal_test::before 1]"

    mongoose.connect "mongodb://localhost/test"
    mongoose.connection.once "connected", (err)->
      return done(err) if err?

      schema = new mongoose.Schema {}, versionKey: false

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
    console.log "[removal_test::before 2]"
    Record = mongoose.model(MODEL_NAME)
    Record.remove done
    return

  # initialize test data
  before (done) ->
    console.log "[removal_test::before 3]"
    obj =
      _id: (Date.now()).toString(36)
      name: "paginate"
      owner : 'tester'
      createdAt: new Date().setDate(new Date().getDate())

    Record(obj).save done
    return

  before (done) ->
    REDIS_CLIENT.flushall()
    setTimeout done, 1800
    return

  describe "mongoose-taggable-via-redis", ->

    @timeout 10000

    it "should clean up tags upon record removal", (done)->
      Record.findOne (err, item)->
        should.not.exist err
        item.setTags TAGS_NODE, (err)->
          should.not.exist err
          Record.popularTags 10, (err, tags)->
            should.not.exist err
            tags.length.should.above 1
            item.remove (err)->
              should.not.exist err
              setTimeout (->
                Record.popularTags 10, (err, tags2)->
                  console.log "[removal_test] tags2:"
                  console.dir tags2

                  should.not.exist err
                  tags2.should.be.empty
                  done()
                  return
                return
              ), 2000

    it "scoped tags should also be cleaned up", (done)->
      Record.popularTags 10, "owner/tester", (err, tags)->
        console.log "[removal_test] tags:"
        console.dir tags

        should.not.exist err
        tags.should.be.empty
        done()
        return


