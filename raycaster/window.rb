module Raycaster
  class Window < Gosu::Window
    attr_reader :resolution

    def initialize
      @resolution = { x: 1280, y: 960 }
      super(@resolution[:x], @resolution[:y])
      self.caption = 'Raycaster'
      @controls = Controls.new
      @map = Map.new
      @player = Player.new(@controls, @map)
      @camera = Camera.new(self, @map, @player)
      @hud = Hud.new(@player)
    end

    def update
      @player.update
    end

    def draw
      @camera.draw
      @hud.draw
    end
  end
end
