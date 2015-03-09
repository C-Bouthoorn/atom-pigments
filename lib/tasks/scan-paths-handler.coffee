async = require 'async'
fs = require 'fs'
VariableScanner = require '../variable-scanner'

class PathScanner
  constructor: (@path) ->
    @scanner = new VariableScanner

  load: (done) ->
    currentChunk = ''
    currentLine = 0
    currentOffset = 0
    lastIndex = 0

    results = []

    readStream = fs.createReadStream(@path)

    readStream.on 'data', (chunk) =>
      currentChunk += chunk.toString()

      index = lastIndex

      while result = @scanner.search(currentChunk, lastIndex)
        result.lastIndex += index
        result.range[0] += index
        result.range[1] += index
        result.path = @path
        for v in result
          v.path = @path
          v.range[0] += index
          v.range[1] += index

        results.push result
        {lastIndex} = result

      if result?
        currentChunk = currentChunk[lastIndex..-1]
        lastIndex = 0

    readStream.on 'end', ->
      emit('scan-paths:path-scanned', results)
      done()

module.exports = (paths) ->
  async.each(
    paths,
    (path, next) ->
      new PathScanner(path).load(next)
    @async()
  )