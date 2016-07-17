Locflow.cloneArray = (source) ->
  source.map (elm) -> elm

Locflow.mergeObjects = (obj1, obj2) ->
  merged = {}
  merged[key] = value for key, value of obj2
  merged[key] = value for key, value of obj1
  merged
