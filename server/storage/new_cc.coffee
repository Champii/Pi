fs = require 'fs'
zlib = require 'zlib'
bigint = require 'bigint'

DigitNbWithin = (n) ->
  ((((bigint(10).pow(n)).mul(9)).mul(n.add(1))).sub(bigint(10).pow(n.add(1))).add(1)).div(9)

GetContainingDigit = (a, nth) ->
  bigint(10).pow(a.add(1)).sub(1).sub((DigitNbWithin(a.add(1)).sub(nth)).div(a.add(1)))

GetDigitPos = (a, nth) ->
  (DigitNbWithin(a.add(1)).sub(nth)).mod((a.add(1)))

FindLowestInterval = (nth) ->
  i = bigint nth.toString().length - 10
  while DigitNbWithin(i).lt(nth)
    i = i.add(1)
  i.sub(1)

GetDigitAt = (nth) ->
  return 0 if nth.eq(0)
  itv = FindLowestInterval nth
  containingDigit = GetContainingDigit itv, nth
  digitPos = GetDigitPos itv, nth
  digit = containingDigit.toString()
  digit[bigint(digit.length).sub(digitPos).sub(1)]

GetNumberAt = (idx) ->
  GetContainingDigit FindLowestInterval(idx), idx

###
###

Idx = (x) ->
  len = bigint x.toString().length
  (DigitNbWithin(len.sub(1)).add(1)).add((len.mul(x.sub((bigint(10).pow(len.sub(1)))))))

GetFile = (hash) ->
  iOrig = bigint(hash.idx)
  i = bigint(hash.idx)
  res = ''
  lol = 0
  while i.lt(iOrig.add(hash.size))
    nb = GetNumberAt(i).toString()
    res += nb
    console.log lol++
    i = i.add(nb.length)

  res = res.substring 0, DigitNbWithin FindLowestInterval hash.idx
  bigint res


fs.readFile process.argv[2], {encoding: null}, (err, file) ->
  return console.error err if err?

  # console.log 'original file as bigint : ', bigint.fromBuffer(file)

  zlib.gzip file, (err, compressed1) ->
    return console.error err if err?

    console.log 'original file after first compression: '#, bigint.fromBuffer(compressed1)

    idx = Idx bigint.fromBuffer compressed1
    console.log 'found idx : '#, idx

    zlib.gzip idx.toBuffer(), (err, compressed2) ->
      return console.error err if err?

      console.log 'idx after second compression: '#, bigint.fromBuffer(compressed2)

      res =
        idx: compressed2
        size: idx.toString().length

      console.log 'Original size: ', file.length, ', Index size: ', compressed2.length

      ###
      Reverse process :
      ###

      console.log '###'
      console.log '###'
      console.log '###'
      console.log '###'

      zlib.gunzip res.idx, (err, uncompressed1) ->
        return console.error err if err?

        console.log 'idx after first decompression : '#, bigint.fromBuffer(uncompressed1)

        int = bigint.fromBuffer uncompressed1

        res2 =
          idx: int
          size: res.idx.toString().length

        compressedFile = GetFile res2

        console.log 'file found :                           '#, compressedFile

        zlib.gunzip compressedFile.toBuffer(), (err, uncompressed2) ->
          return console.error err if err?

          console.log 'idx after first decompression : '#, bigint.fromBuffer(uncompressed2)

          fs.writeFileSync '/tmp/test.out', uncompressed2
