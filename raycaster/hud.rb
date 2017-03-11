module Raycaster
  class Hud
    def initialize(player)
      @player = player
      @font = Gosu::Font.new(20)
      @color = Gosu::Color::BLACK
    end

    def draw
      x = @player.x.round(2)
      y = @player.y.round(2)
      angle = (@player.direction * 180 / Math::PI).round
      @font.draw(
        "fps: #{Gosu.fps}, x: #{x}, y: #{y}, direction: #{angle}°", 10, 10, 1, 1.0, 1.0, @color
      )
    end
  end
end
