'use strict'

#### Events class
#
# @extends createjs.EventDispatcher
#
# - This class acts as a proxy to the createjs.EventDispatcher class
#
class Events extends createjs.EventDispatcher
  opts: {}

  #### The constructor for the EventManager class
  #
  # @param [Object] options
  # - The options object that is used by the class for configuration purposes (optional)
  #
  constructor: (@options) ->
    # Extend default options to include passed in arguments
    @options = $.extend({}, this.opts, @options)

    Events.initialize(Gallo)

# Assign this class to the Gallo Namespace
Gallo.Events = new Events()
