class ExplorerDirective extends Modulator.Directive 'explorer', '$http', 'dirService', 'userService', 'FileUploader'

  Pre: ->
    @uploader = new @FileUploader
      url: 'api/1/files'

  Post: ->
    console.log @uploader

    @newDirName = ''

    @path = '/'

    @createDir = ->
      if @newDirName.length < 1
        return

      @$http.post '/api/1/directorys/', {name: @newDirName, parent_id: @dirService.current.id, client_id: userService.current.id}
        .success (data) ->
          @dirService.refresh()
          @newDirName = ''

    @enter = (id) ->
      @dirService.fetch id, (dir) ->
        @path += dir.name + '/'

    @parent = (id) ->
      @dirService.fetch id, (dir) ->
        @path =  @path.split('/')[...-2].join('/') + '/'

    @upgrade = (file) ->
      if file.percentage < 100
        return
      $http.put '/api/1/files/' + file.id , {storeLevel: file.storeLevel + 1}
        .success ->
          @dirService.refresh()


    @uploader.onAfterAddingFile = (fileItem) ->
      console.info "onAfterAddingFile", fileItem
      fileItem.upload()
      return

    @uploader.onCompleteItem = (fileItem, response, status, headers) ->
      @dirService.refresh()
      return

ExplorerDirective.Init()
