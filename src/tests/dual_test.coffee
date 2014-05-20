###
# test dual schema
###

## Module dependencies
should = require "should"
mongoose = require 'mongoose'
taggable = require "../mongoose-taggable-via-redis"
redis = require("redis")
async = require "async"

REDIS_CLIENT = redis.createClient()
MODEL_NAME_BOOK = "Book"
MODEL_NAME_FOOD = "Food"

TAGS_BOOK = "javascript,server,programming".split(",").sort()
TAGS_FOOD = "chicken,fish,chips,cola".split(",").sort()

# global reference
schema = undefined
ModelBook = null
ModelFood = null

## Test cases
describe "test dual", ->

  after (done)->
    mongoose.connection.close()
    done()

  # initalize models
  before (done) ->
    console.log "[dual_test::before 1]"

    mongoose.connect "mongodb://localhost/test"
    mongoose.connection.once "connected", (err)->
      return done(err) if err?

      schemaBook = new mongoose.Schema {}, versionKey: false

      schemaBook.add
        _id: String
        name: String
        createdAt: Date
        owner : String

      schemaBook.plugin taggable,
        taggable : "book"
        redisClient : REDIS_CLIENT
        getScope : -> "owner/#{@owner}" # wich scope

      mongoose.model MODEL_NAME_BOOK, schemaBook

      schemaFood = new mongoose.Schema {}, versionKey: false

      schemaFood.add
        _id: String
        name: String
        createdAt: Date
        parent : String

      schemaFood.plugin taggable,
        taggable : "food"
        redisClient : REDIS_CLIENT
        getScope : -> "PARENT:#{@parent}" # wich

      mongoose.model MODEL_NAME_FOOD, schemaFood

      done()


  # clean prev test data
  before (done) ->
    console.log "[dual_test::before 2]"
    ModelBook = mongoose.model(MODEL_NAME_BOOK)
    ModelFood = mongoose.model(MODEL_NAME_FOOD)
    ModelFood.remove (err)->
      done(err) if err?
      ModelBook.remove done
    return

  # initialize test data
  before (done) ->
    console.log "[dual_test::before 3]"
    obj =
      _id: (Date.now()).toString(36)
      name: "paginate"
      owner : 'tester'
      parent: 'bigboss'
      createdAt: new Date().setDate(new Date().getDate())

    ModelBook(obj).save (err)->
      done(err) if err?
      ModelFood(obj).save done
    return

  before (done) ->
    REDIS_CLIENT.flushall()
    setTimeout done, 1800
    return

  describe "mongoose-taggable-via-redis", ->

    @timeout 10000

    it "dual models could both set tags: ModelBook", (done)->
      ModelBook.findOne (err, item)->
        should.not.exist err
        item.setTags TAGS_BOOK, (err)->
          should.not.exist err
          ModelBook.findWithTags _id:item.id, (err, items)->
            should.not.exist err
            items[0].tags.sort().should.containDeep(TAGS_BOOK)
            done()


    it "dual models could both set tags: ModelFood", (done)->
      ModelFood.findOne (err, item)->
        should.not.exist err
        item.setTags TAGS_FOOD, (err)->
          should.not.exist err
          ModelFood.findWithTags _id:item.id, (err, items)->
            should.not.exist err
            items[0].tags.sort().should.containDeep(TAGS_FOOD)
            done()

    it "tags in both model should not mixed: ModelBook", (done)->
      ModelBook.popularTags 10, (err, tags)->
        should.not.exist err
        console.log "[dual_test] ModelBook tags:"
        console.dir tags
        tags = tags.map((item)-> item[0])
        tags.sort().should.containDeep TAGS_BOOK
        tags.sort().should.not.containDeep TAGS_FOOD
        done()

    it "(scoped) tags in both model should not mixed: ModelBook", (done)->
      ModelBook.popularTags 10, "owner/tester", (err, tags)->
        should.not.exist err
        console.log "[dual_test] ModelBook tags:"
        console.dir tags
        tags = tags.map((item)-> item[0])
        tags.sort().should.containDeep TAGS_BOOK
        tags.sort().should.not.containDeep TAGS_FOOD
        done()

    it "tags in both model should not mixed: ModelFood", (done)->
      ModelFood.popularTags 10, (err, tags)->
        should.not.exist err
        console.log "[dual_test] ModelFood tags:"
        console.dir tags
        tags = tags.map((item)-> item[0])
        tags.sort().should.not.containDeep TAGS_BOOK
        tags.sort().should.containDeep TAGS_FOOD
        done()

    it "(scoped) tags in both model should not mixed: ModelFood", (done)->
      ModelFood.popularTags 10, "PARENT:bigboss",(err, tags)->
        should.not.exist err
        console.log "[dual_test] ModelFood tags:"
        console.dir tags
        tags = tags.map((item)-> item[0])
        tags.sort().should.not.containDeep TAGS_BOOK
        tags.sort().should.containDeep TAGS_FOOD
        done()








