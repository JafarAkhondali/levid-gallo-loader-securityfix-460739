'use strict'

#### Loader class
#
# @extends UI
#
# - This class extends the Gallo base class
#
class Loader extends Gallo
  opts:
    map:            undefined
    manifest:       undefined
    manifestCache:  undefined
    preload:        undefined
    loader:         undefined
    w:              undefined
    h:              undefined
    onReload:       undefined
    lazy:           undefined

  #### The constructor for the Loader class
  #
  # @param [Object] options
  # - The options object that is used by the class for configuration purposes (optional)
  #
  constructor: (@options) ->
    # Extend default options to include passed in arguments
    @options        = $.extend({}, this.opts, @options)
    @manifestCache  = @options.manifest.slice()
    @manifest       = @options.manifest or []
    @preload        = @options.preload or undefined
    @loader         = @options.loader or undefined
    @lazy           = @options.lazy or false
    @map            = {}
    @w              = 238
    @h              = 170

    Gallo.Events.addEventListener "reset",            @options.onReset or ->
    Gallo.Events.addEventListener "complete",         @options.onComplete or ->
    Gallo.Events.addEventListener "fileStart",        @options.onFileStart or ->
    Gallo.Events.addEventListener "loadStart",        @options.onLoadStart or ->
    Gallo.Events.addEventListener "fileProgress",     @options.onFileProgress or ->
    Gallo.Events.addEventListener "fileError",        @options.onFileError or ->
    Gallo.Events.addEventListener "fileLoaded",       @options.onFileLoaded or ->
    Gallo.Events.addEventListener "overallProgress",  @options.onOverallProgress or ->
    Gallo.Events.addEventListener "manifestLoaded",   @options.onManifestLoaded or @handleManifestLoaded

    @init()

    # return this to make this class chainable
    return this

  init: () ->
    @reset()
    @loadAll()

  reset: () ->
    # If there is an open preload queue, close it.
    @preload.close() if @preload?
    @manifest = @manifestCache.slice()
    @map = {}

    # Create a preloader. There is no manifest added to it up-front, we will add items on-demand.
    @preload = new createjs.LoadQueue(true, "assets/")
    createjs.Sound.registerPlugin(createjs.HTMLAudioPlugin) # need this so it doesn't default to Web Audio
    @preload.installPlugin(createjs.Sound)

    # see: http://createjs.com/Docs/PreloadJS/classes/LoadQueue.html
    @preload.addEventListener "loadstart",      @handleLoadStart
    @preload.addEventListener "filestart",      @handleFileStart
    @preload.addEventListener "fileload",       @handleFileLoaded
    @preload.addEventListener "progress",       @handleOverallProgress
    @preload.addEventListener "fileprogress",   @handleFileProgress
    @preload.addEventListener "error",          @handleFileError
    @preload.addEventListener "complete",       @handlePreloadComplete
    @preload.setMaxConnections 5

    Gallo.Events.dispatchEvent 'reset'

  stop: () ->
    @preload.close() if @preload?

  updateItemList: (item, container) ->
    @map[item] = container # Store a reference to each item by its src

  loadAll: () ->
    @loadAnother() while @manifest.length > 0

  loadAnother: () ->
    # Get the next manifest item, and load it
    item = @manifest.shift()

    # If we have no more items, disable the UI.
    if @manifest.length is 0
      event.options =
        item: item # Get the next manifest item, and load it
        manifest: @manifest
      Gallo.Events.dispatchEvent 'manifestLoaded', event

    # Create a new loader display item
    div = $("#template").clone()
    if @lazyLoad().isOn() is true
      img = $("<img />")
      img.addClass "lazy"
      img.attr "src", "assets/grey.jpg"
      img.attr "data-original", "assets/#{item}"
      img.attr "width", @w
      img.attr "height", @h
      div.append img
    div.attr "id", "" # Wipe out the ID
    div.addClass "box"
    $("#container").append div
    @updateItemList(item, div)

    if @lazyLoad().isOn() is true and @getImageType(item) is 'image'
      $(img).lazyload
        event: 'render'
        effect: 'fadeIn'
      $(img).trigger("render")
    else
      @preload.loadFile item

    event.options =
      item: item # Get the next manifest item, and load it
      manifest: @manifest
    Gallo.Events.dispatchEvent 'loadAnother', event

  getImageType: (item) ->
    itemType = item.split('.')?.pop()
    if itemType is 'jpg' or itemType is 'png' or itemType is 'gif' or itemType is 'svg' then itemType = 'image'
    itemType

  lazyLoad: () ->
    on: () => @lazy = true
    off: () => @lazy = false
    isOn: () => if @lazy is true then true else false

  loadSeveral: (num) ->
    totalItems = @manifest.length
    @loadAnother() while @manifest.length > totalItems - num

  # File complete handler
  handleFileLoaded: (event) =>
    event.options =
      item: @map[event.item.src] # Lookup the related item
      w: @w
      h: @h

    item    = @map[event.item.src]
    result  = event.result
    div     = item

    switch event.item.type
      when createjs.LoadQueue.CSS
        (document.head or document.getElementsByTagName("head")[0]).appendChild result
        div.append "<label>CSS Loaded</label>"

      when createjs.LoadQueue.IMAGE
        div.text ""
        div.addClass("complete")
        r = result.width / result.height
        ir = @w / @h
        if (r > ir)
          result.width = @w
          result.height = @w / r
        else
          result.height = @h
          result.width = @h
        div.append result

      when createjs.LoadQueue.JAVASCRIPT
        document.body.appendChild result
        div.addClass("complete")
        div.append "<label>JavaScript Loaded</label>"

      when createjs.LoadQueue.JSON, createjs.LoadQueue.JSONP
        console.log result
        div.addClass("complete")
        div.append "<label>JSON loaded</label>"

      when createjs.LoadQueue.XML
        console.log result
        div.addClass("complete")
        div.append "<label>XML loaded</label>"

      when createjs.LoadQueue.SOUND
        $(event.item).addClass("complete")
        document.body.appendChild result
        result.play()
        # div.html "<label>Sound Loaded</label>"

      when createjs.LoadQueue.SVG
        div.addClass("complete")
        div.append result

    Gallo.Events.dispatchEvent 'fileLoaded', event

  # File progress handler
  handleFileProgress: (event) =>
    event.options =
      item: @map[event.item.src] # Lookup the related item
      progress: event.progress # Return the progress percentage
    Gallo.Events.dispatchEvent 'fileProgress', event

  # Overall progress handler
  handleOverallProgress: (event) =>
    event.options =
      preload: @preload # Return the preload object
    Gallo.Events.dispatchEvent 'overallProgress', event

  # An error happened on a file
  handleFileError: (event) =>
    event.options =
      item: @map[event.item.src] # Lookup the related item
    Gallo.Events.dispatchEvent 'fileError', event

  handleFileStart: (event) =>
    event.options =
      item: @map[event.item.src] # Lookup the related item
    Gallo.Events.dispatchEvent 'fileStart', event

  handleLoadStart: (event) =>
    event.options =
      preload: @preload # Return the preload object
    Gallo.Events.dispatchEvent 'loadStart', event

  handlePreloadComplete: (event) =>
    Gallo.Events.dispatchEvent 'complete', event

  handleManifestLoaded: (event) ->
    $(".loadButton").attr("disabled", "disabled");
    $(".loadButton .reload").css("display", "inline");

# Assign this class to the Gallo Namespace
Gallo.Loader = Loader
