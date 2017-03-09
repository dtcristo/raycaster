module Raycaster
  class Camera
    def initialize(window, map, player)
      @window = window
      @resolution = window.resolution
      @map = map
      @player = player
      @range = 10
      @focal_length = 0.8
      @spacing = 1
    end

    def draw
      draw_roof
      draw_floor
      draw_walls
    end

    private

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

    def draw_walls
      (1..@resolution[:x]).each do |column|
        x = column.to_f / @resolution[:x] - 0.5
        angle = Math.atan2(x, @focal_length)
        ray = cast(@player.x, @player.y, @player.direction + angle)
        draw_column(column, ray, angle)
      end
    end

    def cast(x, y, angle)
      sin = Math.sin(angle)
      cos = Math.cos(angle)
      do_cast(sin, cos, { x: x, y: y, height: 0, distance: 0 });
    end

    def do_cast(sin, cos, origin)
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
        [origin].concat(do_cast(sin, cos, next_step))
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

    def draw_column(column, ray, angle)
      left = (column * @spacing).floor
      width = @spacing.ceil
      ray.reverse.each_with_index do |step, i|
        if step[:height] == 1
          wall = project(step[:height], angle, step[:distance])
          brightness = (@range - step[:distance]) / @range
          color = Gosu::Color.from_hsv(215, 0.2, brightness)
          @window.draw_line(
            left, wall[:top], color,
            left, wall[:bottom], color
          )
        end
      end
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
  end
end
