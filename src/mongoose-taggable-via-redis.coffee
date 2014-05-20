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
  debuglog "[init] schema:#{schema}"

  taggable = new Taggable(options)

  if options.getScope?
    assert 'function' is typeof options.getScope, "options.getScope is not a function"

  schema
  .virtual('tags')
  .set( (val)->
    @_tags = val
  )
  .get( ()-> return this._tags)


  ## instance methods

  # set tags to an instance
  schema.methods.setTags = (tags, callback)->
    debuglog "[setTags] id:#{@id}, tags:#{tags}"

    scope = if options.getScope then options.getScope.apply(@) else null
    taggable.set @id, tags, scope, callback
    return

  ## static methds
  schema.post 'remove', (record)->
    debuglog "[on remove] record:#{record}"
    # remove tags belong to this record
    record.setTags null
    return

  # get popular tags of specified amount
  schema.statics['popularTags'] = (count, scope, callback)->
    debuglog "[popularTags] count:#{count}"
    taggable.popular count, scope, callback
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

    taggable.find tags, scope, (err, ids)=>
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

      debuglog "[findWithTags] ids:#{ids}, scope:#{scope}, taggable:#{taggable}"

      taggable.get ids, scope, (err, tagsArray)->

        return callback?(err) if err?
        for object, i in results
          object.tags = tagsArray[i]

        callback?(null, results)
        return
    return

  ## pre/post hooks


  ## query extension

  # exec, and return results with tags
  mongoose.Query::execWithTag = (callback) ->
    debuglog "[execWithTag ]"
    @exec (err, results) =>
      return callback?(err) if err?
      return callback?(null, results) unless Array.isArray(results) and results.length > 0

      ids = results.map getIdFromResult
      scope = if options.getScope then options.getScope.apply(results[0]) else null

      taggable.get ids, scope, (err, tags)->
        return callback?(err) if err?
        for object, i in results
          object.tags = tags[i]

        callback null, results
        return

      return
    return

  return




