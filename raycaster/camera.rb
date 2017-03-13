module Raycaster
  class Camera
    attr_reader :rays

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
      calculate_angles
      calculate_rays_and_walls
    end

    def draw
      calculate_rays_and_walls if player_changed?
      # draw_roof
      draw_floor
      # draw_walls
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

    def calculate_angles
      @angles = {}
      @floor_coordinates = {}
      mid = @window.resolution[:y] / 2
      (0..@resolution[:x]-1).each do |column|
        x_scaled = column.to_f / @resolution[:x] - 0.5
        relative_angle = Math.atan2(x_scaled, @focal_length)
        @angles[column] = relative_angle
        (mid..@window.resolution[:y]-1).each do |row|
          wall_height = 2 * (row.to_f - mid)
          next if wall_height <= 0
          relative_y = @window.resolution[:y] / wall_height
          distance = relative_y / Math.cos(relative_angle)
          relative_x = distance * Math.sin(relative_angle)
          @floor_coordinates[[column, row]] = {
            distance: distance, x: relative_x, y: relative_y
          }
        end
      end
    end

    def calculate_rays_and_walls
      @rays = []
      @walls = []
      (0..@resolution[:x]-1).each do |column|
        relative_angle = @angles[column]
        absolute_angle = @player.direction + relative_angle
        x_comp = Math.sin(absolute_angle)
        y_comp = -Math.cos(absolute_angle)
        origin = { x: @player.x, y: @player.y, height: 0, distance: 0 }
        ray = cast(x_comp, y_comp, [origin])
        @rays << ray
        @walls << calculate_strip(column, relative_angle, ray)
      end
      @walls.compact!
    end

    def cast(x_comp, y_comp, steps)
      last_step = steps.last
      step_x = step(y_comp, x_comp, last_step[:x], last_step[:y], false)
      step_y = step(x_comp, y_comp, last_step[:y], last_step[:x], true)
      next_step = if step_x[:length_sq] < step_y[:length_sq]
        inspect(x_comp, y_comp, step_x, 1, 0, last_step[:distance], step_x[:y])
      else
        inspect(x_comp, y_comp, step_y, 0, 1, last_step[:distance], step_y[:x])
      end
      return steps if next_step[:distance] > @range # Range reached, end cast
      steps << next_step
      return steps if next_step[:height] > 0 # Hit wall, end cast
      cast(x_comp, y_comp, steps) # No collision, continue cast
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
      if (shift_x == 0)
        step[:shading] = y_comp > 0 ? :north : :south
      else
        step[:shading] = x_comp < 0 ? :east : :west
      end
      step[:offset] = offset - offset.floor
      step
    end

    def calculate_strip(column, relative_angle, ray)
      hit = nil
      ray.reverse.each do |step|
        hit = step if step[:height] == 1
      end
      if hit
        hit_to_strip(column, relative_angle, hit)
      else
        nil
      end
    end

    def hit_to_strip(column, relative_angle, hit)
      left = (column * @spacing).floor
      width = @spacing.ceil
      wall = project(hit[:height], relative_angle, hit[:distance])
      brightness = ((@range - hit[:distance]) / @range) * (1 - 0.2) + 0.2
      # brightness = 1
      color =
        case(hit[:shading])
        when :north
          Gosu::Color.from_hsv(180, 0.2, brightness)
        when :south
          Gosu::Color.from_hsv(315, 0.2, brightness)
        when :east
          Gosu::Color.from_hsv(225, 0.2, brightness)
        when :west
          Gosu::Color.from_hsv(270, 0.2, brightness)
        end
      # color.alpha = 128

      # roof_quad = nil
      # if wall[:top] > 0
      #   c1 = Gosu::Color::WHITE
      #   c2 = Gosu::Color::BLACK
      #   bottom = wall[:top]
      #   roof_quad = {
      #     x1: left, y1: 0, c1: c1,
      #     x2: left+width, y2: 0, c2: c1,
      #     x3: left, y3: bottom, c3: c2,
      #     x4: left+width, y4: bottom, c4: c2
      #   }
      # end

      floor_quad = nil
      if wall[:bottom] < @window.resolution[:y]
        c1 = Gosu::Color::BLACK
        c2 = Gosu::Color::WHITE
        top = wall[:bottom].floor
        floor_quad = {
          x1: left, y1: top, c1: c1,
          x2: left+width, y2: top, c2: c1,
          x3: left, y3: @window.resolution[:y], c3: c2,
          x4: left+width, y4: @window.resolution[:y], c4: c2
        }
      end

      {
        x1: left, y1: wall[:top], c1: color,
        x2: left+width, y2: wall[:top], c2: color,
        x3: left, y3: wall[:bottom], c3: color,
        x4: left+width, y4: wall[:bottom], c4: color,
        i_left: (@texture.width*hit[:offset]).floor, i_top: 0,
        i_width: 1, i_height: @texture.height,
        # roof_quad: roof_quad,
        floor_quad: floor_quad
      }
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
          0
        )
        # roof_quad = strip[:roof_quad]
        # if roof_quad
        #   @window.draw_quad(
        #     roof_quad[:x1], roof_quad[:y1], roof_quad[:c1],
        #     roof_quad[:x2], roof_quad[:y2], roof_quad[:c2],
        #     roof_quad[:x3], roof_quad[:y3], roof_quad[:c3],
        #     roof_quad[:x4], roof_quad[:y4], roof_quad[:c4]
        #   )
        # end
        floor_quad = strip[:floor_quad]
        if floor_quad
          @window.draw_quad(
            floor_quad[:x1], floor_quad[:y1], floor_quad[:c1],
            floor_quad[:x2], floor_quad[:y2], floor_quad[:c2],
            floor_quad[:x3], floor_quad[:y3], floor_quad[:c3],
            floor_quad[:x4], floor_quad[:y4], floor_quad[:c4]
          )
        end
      end
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
        Gosu::Color::BLACK,
        @window.resolution[:x], @window.resolution[:y]/2,
        Gosu::Color::BLACK,
        0, @window.resolution[:y],
        Gosu::Color::WHITE,
        @window.resolution[:x], @window.resolution[:y],
        Gosu::Color::WHITE,
        0
      )
    end
  end
end
