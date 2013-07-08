'use strict'

#### Gallo base class
#
class Gallo
  opts: {}

  #### The constructor for the Gallo base class
  #
  # @param [Object] options
  # - The options object that is used by the class for configuration purposes (optional)
  #
  constructor: (@options, callback) ->
    # Extend default options to include passed in arguments
    @options = $.extend({}, this.opts, @options)
    callback = callback or (args) ->

    callback(this)

    # return this to make this class chainable
    return this

# Assign this class to the Gallo Namespace
window.Gallo = Gallo