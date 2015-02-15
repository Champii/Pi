class WorkerService extends Nodulator.Service 'worker', '$http', 'socket', '$rootScope'

  # Init: ->
  #   @ccFS = new CcFS()

  # Connect: ->
  #   @$http.get '/api/1/fileclusters'
  #     .success (@fileCluster) =>
  #       console.log @fileCluster
  #       @$http.get '/api/1/fileclusters/' + @fileCluster.id + '/file'
  #         .success (file) =>
  #           @ccFS.GetHash file, 2, (err, idxs) =>
  #             console.log 'Yeah', err, idxs

WorkerService.Init()
