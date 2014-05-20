##
# mongoose-taggable-via-redis
# https://github.com/yi/mongoose-taggable-via-redis
#
# Copyright (c) 2014 yi
# Licensed under the MIT license.
##

# default plugin options values
Taggable = require "taggable-via-redis"
assert = require "assert"
debuglog = require("debug")("mongoose-taggable")
mongoose = require 'mongoose'

getIdFromResult = (result) -> result._id || result.id

findCallbackFromArguments = (args)->
  theCallback = null
  for i in [0...args.length]
    if "function" is typeof args[i]
      return i
  return -1

# mongoose-times plugin method
module.exports = exports  = (schema, options)->
  debuglog "[init] schema:#{schema}"

  taggable = new Taggable(options)

  schema
  .virtual('tags')
  .set( (val)->
    @_tags = val
  )
  .get( ()-> return this._tags)


  # instance methods
  schema.methods.setTags = (tags, callback)->
    debuglog "[setTags] id:#{@id}, tags:#{tags}"

    scope = options.getScope?(@)
    taggable.set @id, tags, scope, callback
    return

  schema.statics['popularTags'] = taggable.popular

  schema.statics['findByTags'] = (tags, scope, callback) ->
    if 'function' is typeof scope
      callback = scope
      scope = null
    taggable.find tags, scope, (err, ids)->
      return callback err if err?
      @find _id : $in : ids, callback
      return

  schema.statics['findWithTags'] = (conditions, callback) ->
    debuglog "[findWithTags]"
    if "function" is typeof conditions
      callback = conditions
      conditions = {}

    @find conditions, (err, results)->
      return callback?(err) if err?
      # lazy
      return callback?(null, results) unless Array.isArray(results) and results.length > 0

      ids = results.map getIdFromResult
      scope = options.getScope?(results[0])

      debuglog "[findWithTags] ids:#{ids}, scope:#{scope}, taggable:#{taggable}"

      taggable.get ids, scope, (err, tagsArray)->
        debuglog "[findWithTags] err:#{err}, tagsArray !!!!!:#{tagsArray}"

        return callback?(err) if err?
        for object, i in results
          debuglog "[method] before"
          console.dir object
          object.tags = tagsArray[i]
          debuglog "[method] after"
          console.dir object
          debuglog "[method] after, tags:#{object.tags}"

        callback?(null, results)
        return
    return


  mongoose.Query::execWithTag = (callback) ->
    @exec (err, results) =>
      return callback?(err) if err?
      return callback?(null, results) unless Array.isArray(results) and results.length > 0

      ids = results.map getIdFromResult
      scope = options.getScope?(results[0])

      taggable.get ids, scope, (err, tags)->
        return callback?(err) if err?
        for object, i in results
          object.tags = tags[i]

        callback null, results
        return

      return
    return

  return




