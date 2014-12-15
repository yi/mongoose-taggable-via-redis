# mongoose-taggable-via-redis [![Build Status](https://secure.travis-ci.org/yi/mongoose-taggable-via-redis.png?branch=master)](http://travis-ci.org/yi/mongoose-taggable-via-redis)

a mongoose plugin that provides tagging ability to the mongoose data model via redis,

Tagging in redis is super fast and flexable. This plugin uses [taggable-via-redis](https://www.npmjs.org/package/taggable-via-redis) to provide a better tagging functionality to the mongoose data model

This plugin also supports scope tagging

**This plugin adds the following methods to the mongoose data model:**

### Static Methods
 * DataModel.popularTags(count:Number, scope:String(optional), callback:Function)
 * DataModel.findByTags(tags:[String || String[]], query:MQuery(optional), scope:String(optional), callback:Function)
 * DataModel.findWithTags(conditions:MCondition, callback:Function)

### Query Extension
  * execWithTag -- will call exec() and inject tags into each found data model instance

### Instance Methods
 * instance.setTags(tags:Array, callback:Function)

### Instance Properties
 * instance.tags -- returns an array of all tags belonging to the data model instance

### Init Options

 * taggable -- name of taggable object
 * prefix  -- [optional] redis key prefix
 * redisClient  -- [optional] use existing redis client, when override redisPort and redisHost options
 * redisPort -- [optional] custom redis port
 * redisHost -- [optional] custom redis host
 * getScope -- [optional] a function that figures out scope from the data model instance

## Install
Install the module with:

```bash
npm install mongoose-taggable-via-redis
```

## Usage
[see test](lib/tests/basic_test.js)

## Test

    npm test

## License
Copyright (c) 2014 yi
Licensed under the MIT license.
