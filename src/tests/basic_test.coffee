###
# test for basic
###

## Module dependencies
should = require "should"
mongoose = require 'mongoose'
taggable = require "../mongoose-taggable-via-redis"

MODEL_NAME = "Record"

# global reference
db = undefined
schema = undefined

## Test cases
describe "test basic", ->

  # initalize models
  before (done) ->

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

      schema.plugin taggable,
        limit: 5

      mongoose.model MODEL_NAME, schema
      done()


  # clean prev test data
  before (done) ->
    mongoose.model(MODEL_NAME).remove done
    return


  # initialize test data
  before (done) ->
    arr = []
    i = 100

    while i >= 1
      arr.push i
      i--
    async.each arr, ((i, cb) ->
      obj =
        _id: (Date.now() + i).toString(36)
        name: "paginate_" + i
        createdAt: new Date().setDate(new Date().getDate() - i)

      mongoose.model(MODEL_NAME)(obj).save cb
      return
    ), done
    return


    describe "basic", ->

      it "should", () ->


