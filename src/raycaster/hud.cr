module Raycaster
  class Hud

    @window : Window
    @map : Map
    @player : Player
    @camera : Camera
    @color : SF::Color
    @map_origin : NamedTuple(x: Int32, y: Int32)
    @player_size : Int32
    @half_player_size : Int32

    def initialize(window, map, player, camera)
      @window = window
      @map = map
      @player = player
      @camera = camera
      @font_size = 24
      @font = SF::Font.from_file("assets/iosevka-slab-regular.ttf")
      @color = SF::Color::White
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

    private def draw_map
      Gosu.translate(@map_origin[:x], @map_origin[:y]) do
        # Draw cells
        (0..@map.size-1).each do |x|
          (0..@map.size-1).each do |y|
            next unless @map.get(x, y) > 0
            Gosu.draw_rect(
              x*@map_scale, y*@map_scale,
              @map_scale, @map_scale, Gosu::Color::WHITE
            )
          end
        end
        # Draw FOV
        @camera.rays.each do |ray|
          Gosu.draw_line(
            ray.first[:x]*@map_scale, ray.first[:y]*@map_scale,
            Gosu::Color::BLUE,
            ray.last[:x]*@map_scale, ray.last[:y]*@map_scale,
            Gosu::Color::BLUE
          )
        end
        # Draw player
        Gosu.draw_rect(
          @player.x*@map_scale - @half_player_size,
          @player.y*@map_scale - @half_player_size,
          @player_size, @player_size, Gosu::Color::RED
        )
      end
    end

    private def draw_stats
      Gosu.translate(20, 20) do
        x = @player.x.round(1)
        y = @player.y.round(1)
        angle = Gosu.radians_to_degrees(@player.direction).round
        @font.draw("fps: #{Gosu.fps}", 0, 0, 1, 1, 1, @color)
        @font.draw("x: #{x}", 0, @font_size, 1, 1, 1, @color)
        @font.draw("y: #{y}", 0, 2*@font_size, 1, 1, 1, @color)
        @font.draw("direction: #{angle}°", 0, 3*@font_size, 1, 1, 1, @color)
      end
    end
  end
end
