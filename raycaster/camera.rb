module Raycaster
  class Camera
    def initialize(window, map, player)
      @window = window
      @resolution = window.resolution
      @map = map
      @player = player
      @old_player = player_hash
      @range = 10
      @focal_length = 0.8
      @spacing = 1
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
        0, 0, 0xff_87ceeb,
        @resolution[:x], 0, 0xff_87ceeb,
        0, @resolution[:y] / 2, 0xff_000000,
        @resolution[:x], @resolution[:y] / 2, 0xff_000000, 0
      )
    end

    def draw_floor
      @window.draw_quad(
        0, @resolution[:y] / 2, 0xff_000000,
        @resolution[:x], @resolution[:y] / 2, 0xff_000000,
        0, @resolution[:y], 0xff_331900,
        @resolution[:x], @resolution[:y], 0xff_331900, 0
      )
    end

    def calculate_angles
      angles = {}
      (1..@resolution[:x]).each do |column|
        x = column.to_f / @resolution[:x] - 0.5
        angles[column] = Math.atan2(x, @focal_length)
      end
      angles
    end

    def calculate_walls
      @walls = []
      (1..@resolution[:x]).each do |column|
        relative_angle = @angles[column]
        absolute_angle = @player.direction + relative_angle
        sin = Math.sin(absolute_angle)
        cos = Math.cos(absolute_angle)
        origin = { x: @player.x, y: @player.y, height: 0, distance: 0 }
        ray = cast(sin, cos, origin)
        @walls << calculate_column(column, ray, relative_angle)
      end
      @walls.compact!
      @walls
    end

    def cast(sin, cos, origin)
      step_x = step(sin, cos, origin[:x], origin[:y], false);
      step_y = step(cos, sin, origin[:y], origin[:x], true);
      next_step = if step_x[:length_sq] < step_y[:length_sq]
        inspect(sin, cos, step_x, 1, 0, origin[:distance], step_x[:y])
      else
        inspect(sin, cos, step_y, 0, 1, origin[:distance], step_y[:x])
      end
      if next_step[:distance] > @range
        [origin]
      else
        [origin].concat(cast(sin, cos, next_step))
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

    def inspect(sin, cos, step, shift_x, shift_y, distance, offset)
      dx = cos < 0 ? shift_x : 0
      dy = sin < 0 ? shift_y : 0
      step[:height] = @map.get(step[:x] - dx, step[:y] - dy)
      step[:distance] = distance + Math.sqrt(step[:length_sq])
      if (shift_x)
        step[:shading] = cos < 0 ? 2 : 0
      else
        step[:shading] = sin < 0 ? 2 : 1
      end
      step[:offset] = offset - offset.floor
      step
    end

    def calculate_column(column, ray, angle)
      line = nil
      left = (column * @spacing).floor
      width = @spacing.ceil
      ray.reverse.each_with_index do |step, i|
        if step[:height] == 1
          wall = project(step[:height], angle, step[:distance])
          brightness = (@range - step[:distance]) / @range
          color = Gosu::Color.from_hsv(215, 0.2, brightness)
          line = {
            x1: left, y1: wall[:top], c1: color,
            x2: left, y2: wall[:bottom], c2: color
          }
        end
      end
      line
    end

    def project(height, angle, distance)
      z = distance * Math.cos(angle);
      wall_height = @resolution[:y] * height / z
      mid = @resolution[:y] / 2
      top = mid - (wall_height / 2)
      bottom = mid + (wall_height / 2)
      {
        top: top,
        bottom: bottom
      }
    end

    def draw_walls
      @walls.each do |line|
        @window.draw_line(
          line[:x1], line[:y1], line[:c1],
          line[:x2], line[:y2], line[:c2]
        )
      end
    end
  end
end
