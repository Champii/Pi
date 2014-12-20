piBuffer = null
piArr = []
fileBuffer = null
fileArr = []

class WorkerService extends Nodulator.Service 'worker', '$http', 'socket', '$rootScope'

  startTime: 0
  found: 0
  partCount: 0

  Init: ->
    @buffer = null
    @currentId = null
    @fileCluster = null
    @logs = []
    @percentage = 0
    @preparePiPercentage = 0
    @prepareFilePercentage = 0
    @res = {}
    @i = 0
    @j = 0
    @testingSpeed = []
    @findingSpeed = []
    @averageTestingTime = 0
    @averageFindingTime = 0
    @perfs = 10

  AppendLog: (log) ->
    @logs.push log

  CalcAverage: ->
    @averageTestingTime = 0
    @averageFindingTime = 0
    tmp = 0

    for test, i in @testingSpeed when i < @testingSpeed.length - 1
      # console.log @testingSpeed[i + 1], test, @testingSpeed[i + 1] - test
      @averageTestingTime += @testingSpeed[i + 1] - test

    if @testingSpeed.length
      @averageTestingTime /= @testingSpeed.length
      @averageTestingTime = Math.floor(1 / (@averageTestingTime / 1000))

    for test, i in @findingSpeed when i < @findingSpeed.length - 1
      # console.log @findingSpeed[i + 1], test, @findingSpeed[i + 1] - test
      @averageFindingTime += @findingSpeed[i + 1] - test

    @averageFindingTime /= @findingSpeed.length if @findingSpeed.length
    @averageFindingTime = Math.floor(1 / (@averageFindingTime / 1000 / 60 )) if @averageFindingTime

  GetTimeElapsed: ->
    Math.floor((new Date().getTime() - @startTime) / 1000)

  MakeBufferArray: (arr, offset) ->
    res = []
    for i in [0...@fileCluster.storeLevel]
      res.push arr[offset + i]
    res

  # Prepare: (arr, buffer, i, percentageName) ->
  #   if i < buffer.length
  #     arr.push @MakeBufferArray buffer, i
  #     @[percentageName] = ((i / buffer.length) * 100).toFixed 1

  #     if not (i % 1000)
  #       setTimeout =>
  #         @$rootScope.$apply =>
  #           @Prepare arr, buffer, ++i, percentageName
  #       , 0
  #     else
  #       @Prepare arr, buffer, ++i, percentageName
  #   else
  #     @[percentageName] = 100
  #     if @preparePiPercentage is 100 and @prepareFilePercentage is 100
  #       @i = 0
  #       @Process()

  PrepareFile: (fileBuffer, i) ->
    if i < fileBuffer.length
      # console.log i
      fileArr.push JSON.stringify(@MakeBufferArray(fileBuffer, i))
      @prepareFilePercentage = ((i / fileBuffer.length) * 100).toFixed 1

      if not (i % 1000)
        setTimeout =>
          @$rootScope.$apply =>
            @PrepareFile fileBuffer, i + @fileCluster.storeLevel
        , 0
      else
        @PrepareFile fileBuffer, i + @fileCluster.storeLevel
    else
      @prepareFilePercentage = 100
      console.log fileArr
      @i = 0
      @Process()

# LOOK INTO PI
  Process: ->
    if @i < piBuffer.length

      # if (j = piArr.indexOf(fileArr[@i])) isnt -1
      if (j = fileArr.indexOf(JSON.stringify @MakeBufferArray piBuffer, @i)) isnt -1
        @res[j] = @i
        @found++
        console.log @i, j, @res

        @findingSpeed.push new Date().getTime()
        if @findingSpeed.length > 100
          @findingSpeed.shift()

      @i++
      # console.log @i

      @testingSpeed.push new Date().getTime()
      if @testingSpeed.length > 100
        @testingSpeed.shift()

      if not (@i % 2000)
        setTimeout =>
          @$rootScope.$apply =>
            @CalcAverage()
            @percentage = ((@i / piBuffer.length) * 100).toFixed 1
            @Process()
        , 0
      else
        @Process()
    else
      @partCount++
      @$http.put '/api/1/fileclusters/' + @fileCluster.id + '/found', {res: @res}
        .success (file) =>
          console.log 'NEW CHUNK'
          fileBuffer = file
          @fileLength = file.length
          @i = 0
          fileArr = []
          @res = {}
          @PrepareFile fileBuffer, 0

        .error (data, code) =>
          console.log data, code
          if code is 500 and data.status is 'changeCluster'
            @Init()
            @Connect()

# #LOOP INTO FILE
#   Process: ->
#     @percentage = ((@i / piBuffer.length) * 100).toFixed 1

#     # if (j = piArr.indexOf(fileArr[@i])) isnt -1
#     if (j = fileArr.indexOf(@MakeBufferArray piBuffer, @i)) isnt -1
#       @res[j] = i
#       @found++
#       console.log @i, j, @res, piArr[@i], piArr

#       @findingSpeed.push new Date().getTime()
#       if @findingSpeed.length > 100
#         @findingSpeed.shift()

#     @i++
#     # console.log @i

#     @testingSpeed.push new Date().getTime()
#     if @testingSpeed.length > 100
#       @testingSpeed.shift()


#     if @i < piBuffer.length
#       if not (@i % 1000)
#         setTimeout =>
#           @$rootScope.$apply =>
#             @CalcAverage()
#             @Process()
#         , 0
#       else
#         @Process()
#     else
#       @$http.put '/api/1/fileclusters/' + @fileCluster.id + '/found', res: @res
#         .success (file) =>
#           fileBuffer = file
#           @fileLength = file.length
#           @PrepareFile fileBuffer, 0
#         .error (data, code) =>
#           console.log data, code
#           if code is 500 and data.status is 'changeCluster'
#             @Init()
#             @Connect()


  Connect: ->
    @startTime = new Date().getTime()
    @$http.post '/api/1/fileclusters'
      .success (@fileCluster) =>
        console.log @fileCluster
        #Hack
        # @fileCluster.storeLevel = 4
        @$http.get '/api/1/fileclusters/' + @fileCluster.id + '/pi'
          .success (pi) =>
            piBuffer = pi
            @piLength = pi.length
            # @Prepare piArr, piBuffer, 0, 'preparePiPercentage'
            @$http.put '/api/1/fileclusters/' + @fileCluster.id + '/found'
              .success (file) =>
                fileBuffer = file
                @fileLength = file.length
                console.log fileBuffer
                # @Prepare fileArr, fileBuffer, 0, 'prepareFilePercentage'
                @PrepareFile fileBuffer, 0

WorkerService.Init()
