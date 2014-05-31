##
# mongoose-taggable-via-redis
# https://github.com/yi/mongoose-taggable-via-redis
#
# Copyright (c) 2014 yi
# Licensed under the MIT license.
##

# default plugin options values
taggable = require "taggable-via-redis"
assert = require "assert"
debuglog = require("debug")("mongoose-taggable")
mongoose = require 'mongoose'
util = require "util"

#mongoose.set('debug', true)
getIdFromResult = (result) -> result._id || result.id

findCallbackFromArguments = (args)->
  theCallback = null
  for i in [0...args.length]
    if "function" is typeof args[i]
      return i
  return -1

# mongoose-times plugin method
module.exports = exports  = (schema, options)->

  assert schema, "missing argument: schema"
  assert options, "missing argument: options"
  assert options.taggable, "missing argument: options.taggable"

  taggable.init(options.redisClient)


  schema["__taggable"] = options

  schema
  .virtual('tags')
  .set( (val)->
    @_tags = val
  )
  .get( ()-> return this._tags)

  # include virtuals in json dump
  schema.set('toJSON', { virtuals: true})
  schema.set('toObject', { virtuals: true})

  ## instance methods

  # set tags to an instance
  schema.methods.setTags = (tags, callback)->
    #options = schema.__taggable
    debuglog "[setTags] moduleName:#{options.taggable}, id:#{@id}, tags:#{tags}"
    #debuglog "[setTags] schema:#{util.inspect(schema, {showHidden:true, colors:true})}"

    scope = if options.getScope then options.getScope.apply(@) else null
    taggable.set options.taggable, @id, tags, scope, callback
    return

  ## static methds

  # get popular tags of specified amount
  schema.statics['popularTags'] = (count, scope, callback)->
    debuglog "[popularTags] count:#{count}"
    taggable.popular options.taggable, count, scope, callback
    return

  # find records of given tags
  schema.statics['findByTags'] = (tags, query, scope, callback) ->
    debuglog "[findByTags] tags:#{tags}, scope:#{scope}"
    if 'function' is typeof scope
      callback = scope
      scope = null
    else if 'function' is typeof query
      callback = query
      scope = null
      query = null

    taggable.find options.taggable, tags, scope, (err, ids)=>
      return callback err if err?
      query = (query || @).where _id : $in : ids
      query.execWithTag callback
      return
    return

  # find, and return results with tags
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
      scope = if options.getScope then options.getScope.apply(results[0]) else null

      debuglog "[findWithTags] ids:#{ids}, scope:#{scope}"

      taggable.get options.taggable, ids, scope, (err, tagsArray)->

        #debuglog "[findWithTags] tagsArray:#{tagsArray}"

        return callback?(err) if err?
        for object, i in results
          object.tags = tagsArray[i]

        callback?(null, results)
        return
    return

  ## pre/post hooks
  schema.post 'remove', (record)->
    debuglog "[on remove] record:#{record}"
    # remove tags belong to this record
    record.setTags options.taggable, null
    return

  ## query extension

  # exec, and return results with tags
  mongoose.Query::execWithTag = (callback) ->
    # getting back the hacked-attached options
    taggableOptions = @.model.schema.__taggable
    #debuglog "[execWithTag ] what is this: #{util.inspect(taggableOptions)}"
    @exec (err, results) =>
      return callback?(err) if err?
      return callback?(null, results) unless Array.isArray(results) and results.length > 0

      ids = results.map getIdFromResult
      scope = if taggableOptions.getScope then taggableOptions.getScope.apply(results[0]) else null

      taggable.get taggableOptions.taggable, ids, scope, (err, tags)->
        return callback?(err) if err?
        for object, i in results
          object.tags = tags[i]

        callback null, results
        return

      return
    return

  return




