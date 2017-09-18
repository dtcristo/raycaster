module Raycaster
  class Window
    getter :resolution

    @controls : Controls
    @map : Map
    @player : Player
    @camera : Camera?
    # @hud : Hud

    def initialize
      @resolution = { x: 1280, y: 960 }
      @window = SF::RenderWindow.new(
        SF::VideoMode.new(@resolution[:x], @resolution[:y]),
        "Float",#"Raycaster",
        settings: SF::ContextSettings.new(depth: 24, antialiasing: 8)
      )
      @window.vertical_sync_enabled = true
      @controls = Controls.new
      @map = Map.new
      @player = Player.new(@controls, @map)
      @camera = Camera.new(self, @map, @player)
      # @hud = Hud.new(self, @map, @player, @camera)
    end

    def update
      @player.update
    end

    def draw
      @camera.draw
      # @hud.draw
    end

    def run
    end
  end
end
