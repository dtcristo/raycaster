require 'gosu'
require 'pry'

require_relative 'raycaster/camera'
require_relative 'raycaster/controls'
require_relative 'raycaster/hud'
require_relative 'raycaster/map'
require_relative 'raycaster/player'
require_relative 'raycaster/window'

module Raycaster
end

Raycaster::Window.new.show
