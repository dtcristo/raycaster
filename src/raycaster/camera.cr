module Raycaster
  class Camera
    getter :rays, :resolution

    @window : Window
    @column_spacing : Int32
    @row_spacing : Int32
    @map : Map
    @player : Player
    @old_player : NamedTuple(x: Float64, y: Float64, direction: Float64)

    alias Floor = NamedTuple(
      x1: Int32, y1: Int32, c1: SF::Color,
      x2: Int32, y2: Int32, c2: SF::Color,
      x3: Int32, y3: Int32, c3: SF::Color,
      x4: Int32, y4: Int32, c4: SF::Color
    )

    alias Wall = NamedTuple(
      x1: Int32, y1: Int32, c1: SF::Color,
      x2: Int32, y2: Int32, c2: SF::Color,
      x3: Int32, y3: Int32, c3: SF::Color,
      x4: Int32, y4: Int32, c4: SF::Color,
      i_left: Int32, i_top: Int32,
      i_width: Int32, i_height: Int32,
      # roof_quad: roof_quad,
      floor_quad: Floor?
    )

    def initialize(window, map, player)
      @window = window
      # @resolution = { x: 160, y: 120 }
      @resolution = { x: 320, y: 240 }
      # @resolution = { x: 1280, y: 960 }
      @column_spacing = @window.resolution[:x] / @resolution[:x]
      @row_spacing = @window.resolution[:y] / @resolution[:y]
      @map = map
      @player = player
      @old_player = player_hash
      @range = 10
      @focal_length = 0.8
      @texture_width, @texture_height = 128, 128
      @texture = SF::Texture.from_file("assets/texture.png", SF.int_rect(0, 0, @texture_width, @texture_height))
      @angles = {} of Int32 => Float64
      @floor_coordinates = {} of Tuple(Int32, Int32) => NamedTuple(distance: Float64, x: Float64, y: Float64)
      calculate_angles
      @rays = [] of Array(InspectedStep)
      @walls = [] of Wall?
      # calculate_rays_and_walls
    end

    def draw
      # draw_roof
      draw_floor
      # calculate_rays_and_walls if player_changed?
      draw_walls
      save_player
    end

    private def player_hash
      { x: @player.x, y: @player.y, direction: @player.direction }
    end

    private def player_changed?
      @old_player != player_hash
    end

    private def save_player
      @old_player = player_hash
    end

    private def calculate_angles
      mid = @resolution[:y] / 2
      (0..@resolution[:x]-1).each do |column|
        x_scaled = column.to_f / @resolution[:x] - 0.5
        relative_angle = Math.atan2(x_scaled, @focal_length)
        @angles[column] = relative_angle
        (mid..@resolution[:y]-1).each do |row|
          wall_height = 2 * (row.to_f - mid)
          next if wall_height <= 0
          relative_y = -@resolution[:y] / wall_height
          distance = -relative_y / Math.cos(relative_angle)
          relative_x = distance * Math.sin(relative_angle)
          @floor_coordinates[{column, row}] = {
            distance: distance, x: relative_x, y: relative_y
          }
        end
      end
    end

    private def calculate_rays_and_walls
      @rays = [] of Array(InspectedStep)
      @walls = [] of Wall?
      (0..@resolution[:x]-1).each do |column|
        relative_angle = @angles[column]
        absolute_angle = @player.direction + relative_angle
        x_comp = Math.sin(absolute_angle)
        y_comp = -Math.cos(absolute_angle)
        initial_steps = [] of InspectedStep
        # origin
        initial_steps << { x: @player.x, y: @player.y, length_sq: 0_f64, height: 0, distance: 0_f64, shading: :north, offset: 0_f64 }
        ray = cast(x_comp, y_comp, initial_steps)
        @rays << ray
        @walls << calculate_strip(column, relative_angle, ray)
      end
      @walls.compact!
    end

    private def cast(x_comp, y_comp, inspected_steps) : Array(InspectedStep)
      last_step = inspected_steps.last
      step_x = step(y_comp, x_comp, last_step[:x], last_step[:y], false)
      step_y = step(x_comp, y_comp, last_step[:y], last_step[:x], true)
      next_step = if step_x[:length_sq] < step_y[:length_sq]
        inspect(x_comp, y_comp, step_x, 1, 0, last_step[:distance], step_x[:y])
      else
        inspect(x_comp, y_comp, step_y, 0, 1, last_step[:distance], step_y[:x])
      end
      return inspected_steps if next_step[:distance] > @range # Range reached, end cast
      inspected_steps << next_step
      return inspected_steps if next_step[:height] > 0 # Hit wall, end cast
      cast(x_comp, y_comp, inspected_steps) # No collision, continue cast
    end

    alias Step = NamedTuple(x: Float64, y: Float64, length_sq: Float64)

    private def step(rise, run, x, y, inverted) : Step
      # Handle possible divide by zero
      return { x: 0_f64, y: 0_f64, length_sq: Float64::INFINITY } if run == 0
      dx = run > 0 ? (x + 1).floor - x : (x - 1).ceil - x
      dy = dx * (rise / run)
      {
        x: inverted ? y + dy : x + dx,
        y: inverted ? x + dx : y + dy,
        length_sq: dx**2 + dy**2
      }
    end

    alias InspectedStep = NamedTuple(x: Float64, y: Float64, length_sq: Float64, height: Int32, distance: Float64, shading: Symbol, offset: Float64)

    private def inspect(x_comp, y_comp, step : Step, shift_x, shift_y, distance, offset) : InspectedStep
      dx = x_comp < 0 ? shift_x : 0
      dy = y_comp < 0 ? shift_y : 0
      height = @map.get(step[:x] - dx, step[:y] - dy)
      new_distance = distance + Math.sqrt(step[:length_sq])
      shading = if (shift_x == 0)
        y_comp > 0 ? :north : :south
      else
        x_comp < 0 ? :east : :west
      end
      new_offset = offset - offset.floor
      { x: step[:x], y: step[:y], length_sq: step[:length_sq], height: height, distance: new_distance, shading: shading, offset: new_offset }
    end

    private def calculate_strip(column, relative_angle, ray) : Wall?
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

    private def hit_to_strip(column, relative_angle, hit) : Wall
      left = (column * @column_spacing).floor
      width = @column_spacing.ceil
      wall = project(hit[:height], relative_angle, hit[:distance])
      brightness = ((@range - hit[:distance]) / @range) * (1 - 0.2) + 0.2
      # brightness = 1
      color =
        case(hit[:shading])
        when :north
          # Gosu::Color.from_hsv(180, 0.2, brightness)
          SF::Color::Red
        when :south
          # Gosu::Color.from_hsv(315, 0.2, brightness)
          SF::Color::Green
        when :east
          # Gosu::Color.from_hsv(225, 0.2, brightness)
          SF::Color::Blue
        when :west
          # Gosu::Color.from_hsv(270, 0.2, brightness)
          SF::Color::Yellow
        else
          SF::Color::White
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
        c1 = SF::Color::Black
        c2 = SF::Color::White
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
        i_left: (@texture_width*hit[:offset]).floor.to_i, i_top: 0,
        i_width: 1, i_height: @texture_height,
        # roof_quad: roof_quad,
        floor_quad: floor_quad
      }
    end

    private def project(height, angle, distance)
      z = distance * Math.cos(angle)
      wall_height = @window.resolution[:y] * height / z
      mid = @window.resolution[:y] / 2
      top = mid - (wall_height / 2)
      bottom = mid + (wall_height / 2)
      {
        top: top.to_i,
        bottom: bottom.to_i
      }
    end

    private def draw_walls
      @walls.each do |maybe_strip|
        maybe_strip.try do |strip|
          # Textured wall
          convex = SF::ConvexShape.new
          convex.texture = @texture
          convex.texture_rect = SF::IntRect.new(strip[:i_left], strip[:i_top], strip[:i_width], strip[:i_height])
          convex.fill_color = strip[:c1]
          convex.point_count = 4
          convex[0] = SF.vector2(strip[:x1], strip[:y1])
          convex[1] = SF.vector2(strip[:x2], strip[:y2])
          convex[3] = SF.vector2(strip[:x3], strip[:y3])
          convex[2] = SF.vector2(strip[:x4], strip[:y4])
          @window.draw_entity(convex)

          # roof_quad = strip[:roof_quad]
          # if roof_quad
          #   @window.draw_quad(
          #     roof_quad[:x1], roof_quad[:y1], roof_quad[:c1],
          #     roof_quad[:x2], roof_quad[:y2], roof_quad[:c2],
          #     roof_quad[:x3], roof_quad[:y3], roof_quad[:c3],
          #     roof_quad[:x4], roof_quad[:y4], roof_quad[:c4]
          #   )
          # end
          strip[:floor_quad].try do |floor_quad|
            @window.draw_quad(
              floor_quad[:x1], floor_quad[:y1], floor_quad[:c1],
              floor_quad[:x2], floor_quad[:y2], floor_quad[:c2],
              floor_quad[:x3], floor_quad[:y3], floor_quad[:c3],
              floor_quad[:x4], floor_quad[:y4], floor_quad[:c4]
            )
          end
        end
      end
    end

    def draw_roof
     @window.draw_quad(
       0, 0,
       Gosu::Color.from_hsv(45, 0.5, 1),
       @window.resolution[:x], 0,
       Gosu::Color.from_hsv(45, 0.5, 1),
       0, @window.resolution[:y] / 2,
       Gosu::Color.from_hsv(45, 0.5, 0.1),
       @window.resolution[:x], @window.resolution[:y] / 2,
       Gosu::Color.from_hsv(45, 0.5, 0.1)
     )
    end

    def draw_floor
      mid = @resolution[:y] / 2
      bottom = @resolution[:y] - 1
      0.upto(@resolution[:x]-1).each do |column|
        bottom.downto(mid).each do |row|
          floor = @floor_coordinates.fetch({column, row}, nil)
          if floor.nil?
            @window.draw_pixel(
              column, row, SF::Color::Green
            )
            next
          end
          height = @map.get(
          @player.x + floor[:x], @player.y + floor[:y]
          )
          if height > 0
            @window.draw_pixel(
              column, row, SF::Color::Blue
            )
            break
          else
            @window.draw_pixel(
              column, row, SF::Color::Red
            )
          end

         # @floor_coordinates[[column, row]] = {
         #   distance: distance, x: relative_x, y: relative_y
         # }
         # point = @floor_coordinates[[column, row]]

        end
      end
    end
  end
end
