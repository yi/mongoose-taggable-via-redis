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

dateJSON = (key) ->
  json = {}
  json[key] = Date
  json


### what's in schema
{ paths:
   { _id:
      { enumValues: [],
        regExp: null,
        path: '_id',
        instance: 'String',
        validators: [],
        setters: [],
        getters: [],
        options: [Object],
        _index: null },
     name:
      { enumValues: [],
        regExp: null,
        path: 'name',
        instance: 'String',
        validators: [],
        setters: [],
        getters: [],
        options: [Object],
        _index: null },
     createdAt:
      { path: 'createdAt',
        instance: undefined,
        validators: [],
        setters: [],
        getters: [],
        options: [Object],
        _index: null } },
  subpaths: {},
  virtuals: { id: { path: 'id', getters: [Object], setters: [], options: {} } },
  nested: {},
  inherits: {},
  callQueue: [],
  _indexes: [],
  methods: {},
  statics: {},
  tree:
   { _id: [Function: String],
     id: { path: 'id', getters: [Object], setters: [], options: {} },
     name: [Function: String],
     createdAt: [Function: Date] },
  _requiredpaths: undefined,
  discriminatorMapping: undefined,
  _indexedpaths: undefined,
  options:
   { versionKey: false,
     id: true,
     noVirtualId: false,
     _id: true,
     noId: false,
     read: null,
     shardKey: null,
     autoIndex: true,
     minimize: true,
     discriminatorKey: '__t',
     capped: false,
     bufferCommands: true,
     strict: true } }

###


# mongoose-times plugin method
module.exports = exports  = (schema, options)->
  debuglog "[init] schema:#{schema}"

  taggable = new Taggable(options)

  # instance methods
  schema.methods.setTags = (tags, callback)->
    debuglog "[setTags] tags:#{tags}"

    scope = options.getScope?(@)
    if scope?
      taggable.set scope, @id, tags, callback
    else
      taggable.set @id, tags, callback
    return

  schema.statics['popularTags'] = (scope, count, callback)->
    debuglog "[popularTags] scope:#{scope}, count:#{count}"
    if scope?
      taggable.popular scope, count, callback
    else
      taggable.popular count, callback
    return

  schema.statics['findByTags'] = (scope, tags, callback) ->
    debuglog "[findByTags] scope:#{scope}, tags:#{tags}"
    if scope?
      taggable.find scope, tags, callback
    else
      taggable.find tags, callback
    return

  mongoose.Query::execWithTag = (callback) ->
    @exec (err, objects) =>
      return callback?(err) if err?
      return callback?(null, []) unless objects

      ids = []
      for object in objects
        ids.push object._id

      handleTags = (err, tags)->
        return callback?(err) if err?
        for object, i in objects
          object.tags = tags[i]

        callback null, objects
        return


      scope = options.getScope?(objects[0])
      if scope
        taggable.get scope, ids, handleTags
      else
        taggable.get ids, handleTags
      return
    return

  return




