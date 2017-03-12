module Raycaster
  class Camera
    def initialize(window, map, player)
      @window = window
      @resolution = { x: 160, y: 120 }
      @spacing = @window.resolution[:x] / @resolution[:x]
      @map = map
      @player = player
      @old_player = player_hash
      @range = 10
      @focal_length = 0.8
      @texture = Gosu::Image.new(
        File.expand_path('../../assets/texture.png', __FILE__), retro: true
      )
      @angles = calculate_angles
      @walls = calculate_walls
    end

    def draw
      draw_roof
      draw_floor
      calculate_walls if player_changed?
      draw_walls
      save_player
    end

    private

    def player_hash
      { x: @player.x, y: @player.y, direction: @player.direction }
    end

    def player_changed?
      @old_player != player_hash
    end

    def save_player
      @old_player = player_hash
    end

    def draw_roof
      @window.draw_quad(
        0, 0,
        Gosu::Color.from_hsv(45, 0.5, 1),
        @window.resolution[:x], 0,
        Gosu::Color.from_hsv(45, 0.5, 1),
        0, @window.resolution[:y]/2,
        Gosu::Color.from_hsv(45, 0.5, 0.1),
        @window.resolution[:x], @window.resolution[:y]/2,
        Gosu::Color.from_hsv(45, 0.5, 0.1),
        0
      )
    end

    def draw_floor
      @window.draw_quad(
        0, @window.resolution[:y]/2,
        Gosu::Color.from_hsv(90, 0.5, 0.1),
        @window.resolution[:x], @window.resolution[:y]/2,
        Gosu::Color.from_hsv(90, 0.5, 0.1),
        0, @window.resolution[:y],
        Gosu::Color.from_hsv(90, 0.5, 1),
        @window.resolution[:x], @window.resolution[:y],
        Gosu::Color.from_hsv(90, 0.5, 1),
        0
      )
    end

    def calculate_angles
      angles = {}
      (0..(@resolution[:x]-1)).each do |column|
        x = column.to_f / @resolution[:x] - 0.5
        angles[column] = Math.atan2(x, @focal_length)
      end
      angles
    end

    def calculate_walls
      @walls = []
      (0..(@resolution[:x]-1)).each do |column|
        relative_angle = @angles[column]
        absolute_angle = @player.direction + relative_angle
        x_comp = Math.sin(absolute_angle)
        y_comp = -Math.cos(absolute_angle)
        origin = { x: @player.x, y: @player.y, height: 0, distance: 0 }
        ray = cast(x_comp, y_comp, origin)
        @walls << calculate_strip(column, ray, relative_angle)
      end
      @walls.compact!
      @walls
    end

    def cast(x_comp, y_comp, origin)
      step_x = step(y_comp, x_comp, origin[:x], origin[:y], false)
      step_y = step(x_comp, y_comp, origin[:y], origin[:x], true)
      next_step = if step_x[:length_sq] < step_y[:length_sq]
        inspect(x_comp, y_comp, step_x, 1, 0, origin[:distance], step_x[:y])
      else
        inspect(x_comp, y_comp, step_y, 0, 1, origin[:distance], step_y[:x])
      end
      if next_step[:distance] > @range
        [origin]
      else
        [origin].concat(cast(x_comp, y_comp, next_step))
      end
    end

    def step(rise, run, x, y, inverted)
      # Handle possible divide by zero
      return { length_sq: Float::INFINITY } if run == 0
      dx = run > 0 ? (x + 1).floor - x : (x - 1).ceil - x
      dy = dx * (rise / run)
      {
        x: inverted ? y + dy : x + dx,
        y: inverted ? x + dx : y + dy,
        length_sq: dx**2 + dy**2
      }
    end

    def inspect(x_comp, y_comp, step, shift_x, shift_y, distance, offset)
      dx = x_comp < 0 ? shift_x : 0
      dy = y_comp < 0 ? shift_y : 0
      step[:height] = @map.get(step[:x] - dx, step[:y] - dy)
      step[:distance] = distance + Math.sqrt(step[:length_sq])
      # step[:shading] = shift_x
      if (shift_x == 0)
        step[:shading] = y_comp > 0 ? :north : :south
      else
        step[:shading] = x_comp < 0 ? :east : :west
      end
      step[:offset] = offset - offset.floor
      step
    end

    def calculate_strip(column, ray, relative_angle)
      strip = nil
      left = (column * @spacing).floor
      width = @spacing.ceil
      ray.reverse.each_with_index do |step, i|
        if step[:height] == 1
          wall = project(step[:height], relative_angle, step[:distance])
          brightness = ((@range - step[:distance]) / @range) * (1 - 0.2) + 0.2
          # color = Gosu::Color.from_hsv(0, 0, brightness)
          color =
            case(step[:shading])
            when :north
              Gosu::Color.from_hsv(180, 0.2, brightness)
            when :south
              Gosu::Color.from_hsv(315, 0.2, brightness)
            when :east
              Gosu::Color.from_hsv(225, 0.2, brightness)
            when :west
              Gosu::Color.from_hsv(270, 0.2, brightness)
            end
          strip = {
            x1: left, y1: wall[:top], c1: color,
            x2: left+width, y2: wall[:top], c2: color,
            x3: left, y3: wall[:bottom], c3: color,
            x4: left+width, y4: wall[:bottom], c4: color,
            i_left: (@texture.width*step[:offset]).floor, i_top: 0,
            i_width: 1, i_height: @texture.height
          }
        end
      end
      strip
    end

    def project(height, angle, distance)
      z = distance * Math.cos(angle)
      wall_height = @window.resolution[:y] * height / z
      mid = @window.resolution[:y] / 2
      top = mid - (wall_height / 2)
      bottom = mid + (wall_height / 2)
      {
        top: top,
        bottom: bottom
      }
    end

    def draw_walls
      @walls.each do |strip|
        texture_strip = @texture.subimage(
          strip[:i_left], strip[:i_top], strip[:i_width], strip[:i_height]
        )
        texture_strip.draw_as_quad(
          strip[:x1], strip[:y1], strip[:c1],
          strip[:x2], strip[:y2], strip[:c2],
          strip[:x3], strip[:y3], strip[:c3],
          strip[:x4], strip[:y4], strip[:c4],
          1
        )
      end
    end
  end
end
