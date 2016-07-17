# The Cache class is a general purpose key-value store. The underlying
# implementation relies on plain old javascript objects, with a few utilities
# such as:
#
# * Optional default value for key (useful for default parameters)
# * Limit the cache size with the latest N items.
# * Expire value after N seconds.
class Locflow.Cache
  constructor: ->
    @data = {}
    @limit = 9999

  # Limits how many elements the cache should keep. If it goes over the limit,
  # older records are removed in order to create space for new ones.
  setSize: (@limit) ->
    @removeExceedingRecords()

  sortedKeysByTime: ->
    sorted = []
    for key of @data
      sorted.push([key, @data[key].timestamp])
    sorted.sort((a,b) -> a[1] - b[1]).map((rec) -> rec[0])

  removeExceedingRecords: ->
    pending = Object.keys(@data).length - @limit
    sortedKeys = @sortedKeysByTime()
    while pending > 0
      key = sortedKeys.shift()
      @remove(key)
      pending -= 1

  put: (key, value) ->
    @data[key] =
      value: value
      timestamp: new Date().getTime()
    @removeExceedingRecords()

  get: (key, defaultValue) ->
    value = @data[key]?.value
    if value is undefined then defaultValue else value

  has: (key) ->
    @get(key) isnt undefined

  remove: (key) ->
    val = @get(key)
    delete @data[key]
    val

  removeAll: ->
    @remove(key) for key of @data
