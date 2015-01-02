class WorkerDirective extends Nodulator.Directive 'worker', 'workerService'

  lol: 0

  Init: ->
    @workerService.Connect()

    # console.log 'lol', $.ionRangeSl
    document.addEventListener "DOMContentLoaded", (event) ->
      $("#perfSlider").ionRangeSlider
        min: 100,
        max: 1000,
        from: 550

WorkerDirective.Init()
