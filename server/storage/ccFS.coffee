fs = require 'fs'
zlib = require 'zlib'
bigint = require 'bigint'

class CcFS

  GetHash: (file, done) ->
    zlib.gzip file, (err, compressed) =>
      return done err if err?

      @_GetHash bigint.fromBuffer(compressed), done

  GetFile: (hash, done) ->
    zlib.gunzip hash.idx, (err, uncompressed) =>
      return done err if err?

      file = @_GetFile
        idx: bigint.fromBuffer uncompressed
        size: bigint hash.size

      zlib.gunzip file.toBuffer(), (err, uncompressed) =>
        return done err if err?

        done null, uncompressed

  _GetHash: (int, done) ->
    hash = @__GetHash int

    zlib.gzip hash.toBuffer(), (err, compressed) =>
      return done err if err?

      int2 = bigint.fromBuffer(compressed)

      if int.toString().length > int2.toString().length
        return @_GetHash int2, done

      done null,
        idx: compressed
        size: int.toString().length

  __GetHash: (file) ->
    len = bigint file.toString().length
    (@_DigitNbWithin(len.sub(1)).add(1)).add((len.mul(file.sub((bigint(10).pow(len.sub(1)))))))

  _GetFile: (hash) ->
    iOrig = bigint(hash.idx)
    i = bigint(hash.idx)
    res = ''
    while i.lt(iOrig.add(hash.size))
      nb = @_GetNumberAt(i).toString()
      res += nb
      i = i.add(nb.length)

    res = res.substring 0, @_DigitNbWithin @_FindLowestInterval hash.idx
    bigint res

  _DigitNbWithin: (n) ->
    ((((bigint(10).pow(n)).mul(9)).mul(n.add(1))).sub(bigint(10).pow(n.add(1))).add(1)).div(9)

  _GetContainingDigit: (a, nth) ->
    bigint(10).pow(a.add(1)).sub(1).sub((@_DigitNbWithin(a.add(1)).sub(nth)).div(a.add(1)))

  _GetDigitPos: (a, nth) ->
    (@_DigitNbWithin(a.add(1)).sub(nth)).mod((a.add(1)))

  _FindLowestInterval: (nth) ->
    i = bigint nth.toString().length - 10
    while @_DigitNbWithin(i).lt(nth)
      i = i.add(1)
    i.sub(1)

  # Unused
  _GetDigitAt: (nth) ->
    return 0 if nth.eq(0)
    itv = @_FindLowestInterval nth
    containingDigit = @_GetContainingDigit itv, nth
    digitPos = @_GetDigitPos itv, nth
    digit = containingDigit.toString()
    digit[bigint(digit.length).sub(digitPos).sub(1)]

  _GetNumberAt: (idx) ->
    @_GetContainingDigit @_FindLowestInterval(idx), idx

module.exports = new CcFS


# ccFS = new CcFS

# fs.readFile process.argv[2], {encoding: null}, (err, file) ->
#   return console.error err if err?

#   ccFS.GetHash file, (err, hash) ->
#     return console.log err if err?

#     ccFS.GetFile hash, (err, file) ->
#       return console.log err if err?

#       console.log file

