module Raycaster
  class Hud
    def initialize(window, map, player)
      @window = window
      @map = map
      @player = player
      @font_size = 24
      @font = Gosu::Font.new(@font_size, name: 'Courier New')
      @color = Gosu::Color::WHITE
      @map_scale = 10
      @map_origin = {
        x: @window.resolution[:x] - @map.size*@map_scale - 40,
        y: 40
      }
      @player_size = (@map_scale/2).round
      @half_player_size = (@player_size/2).round
    end

    def draw
      draw_map
      draw_stats
    end

    def draw_map
      (0..@map.size-1).each do |x|
        (0..@map.size-1).each do |y|
          next unless @map.get(x, y) > 0
          left = @map_origin[:x]+x*@map_scale
          top = @map_origin[:y]+y*@map_scale
          Gosu.draw_rect(
            @map_origin[:x] + x*@map_scale,
            @map_origin[:y] + y*@map_scale,
            @map_scale, @map_scale, Gosu::Color::WHITE
          )
        end
      end

      Gosu.draw_rect(
        @map_origin[:x] + @player.x*@map_scale - @half_player_size,
        @map_origin[:y] + @player.y*@map_scale - @half_player_size,
        @player_size, @player_size, Gosu::Color::RED
      )
    end

    def draw_stats
      x = @player.x.round(1)
      y = @player.y.round(1)
      angle = Gosu.radians_to_degrees(@player.direction).round
      @font.draw("fps: #{Gosu.fps}", 20, 20, 1, 1, 1, @color)
      @font.draw("x: #{x}", 20, 20 + @font_size, 1, 1, 1, @color)
      @font.draw("y: #{y}", 20, 20 + 2*@font_size, 1, 1, 1, @color)
      @font.draw("direction: #{angle}°", 20, 20 + 3*@font_size, 1, 1, 1, @color)
    end
  end
end
