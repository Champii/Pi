_ = require 'underscore'

ccChunkSize = 5000000

# DigitNbWithin_ = (n) ->
#  (9 * (Math.pow(10, n) * (n + 1)) - Math.pow(10, n + 1) + 1) / 9

# Idx_ = (x) ->
#   len = ('' + x).length
#   (DigitNbWithin_(len - 1) + 1) + ((x - Math.pow(10, len - 1)) * len)

class CcFS

  GetHash: (fileBuffer, chunkSize, offset, done) ->
    seqs = @_MakeSeqs fileBuffer, chunkSize
    @_FindAllSequences seqs, offset, done

  GetFile: (idxs, chunksize, done) ->
    res = new Buffer(idxs.length * chunkSize)
    tmp = ''
    count = 0
    for idx in idxs
      i = 0
      while i < chunkSize * 3
        tmp += _GetDigitAt idx + i++
        if tmp.length is 3
          res[count++] = parseInt(tmp)
          tmp = ''
      tmp = ''
    res

  _DigitNbWithin: (n) -> (9 * (Math.pow(10, n) * (n + 1)) - Math.pow(10, n + 1) + 1) / 9

  _GetContainingDigit: (a, nth) ->
    Math.pow(10, a + 1) - 1 - Math.floor((@_DigitNbWithin(a + 1) - nth) / (a + 1))

  _GetDigitPos: (a, nth) -> (@_DigitNbWithin(a + 1) - nth) % (a + 1)

  _FindLowestInterval: (nth) ->
    i = 0
    i++ while @_DigitNbWithin(i) < nth
    i - 1

  _GetDigitAt: (nth) ->
    return 0 if not nth
    itv = @_FindLowestInterval nth
    containingDigit = @_GetContainingDigit itv, nth
    digitPos = @_GetDigitPos itv, nth
    (containingDigit + '')[(containingDigit + '').length - digitPos - 1]

  _FindAllSequences: (seqs, offset, done) ->
    buff = ''
    res = []
    i = offset
    elemCount = 0
    count = 0

    while buff.length < seqs[0].length
      buff += @_GetDigitAt i++

    while elemCount < seqs.length and count < ccChunkSize # TEMP VALUE
      while (idx = seqs.indexOf buff) isnt -1
        if not res[idx]
          elemCount++
          res[idx] = i - buff.length

        process.stdout.cursorTo(0)
        process.stdout.write "Found: " + (elemCount / seqs.length * 100).toFixed(2) + '%'
        process.stdout.write " Bytes tested: " + (count / ccChunkSize * 100).toFixed(2) + '%'
        seqs[idx] = ''

      arrBuff = buff.split('')
      arrBuff.shift()
      arrBuff.push @_GetDigitAt i
      buff = arrBuff.join('')

      i++
      count++

    console.log 'Res !', res
    done null, res

  _MakeSeqs: (file, chunkSize) ->
    seqSize = 0
    tmp = ''
    i = 0
    res = []
    for char in file
      while (char + '').length < 3
        char = '0' + char
      tmp += char
      seqSize++
      if seqSize is chunkSize
        res.push tmp
        seqSize = 0
        tmp = ''
      i++

    res

  _CheckSum: (orig, crafted) ->
    for value, i in orig
      if crafted[i] isnt value
        return false
    return true

module.exports = new CcFS

