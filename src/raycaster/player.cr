module Raycaster
  class Player
    getter :x, :y, :direction

    @controls : Controls
    @map : Map
    @x : Float64
    @y : Float64
    @direction : Float64

    def initialize(controls, map)
      @controls = controls
      @map = map
      @x = @map.spawn_point[:x]
      @y = @map.spawn_point[:y]
      @direction = @map.spawn_point[:direction]
    end

    def update
      if @controls.forward?
        walk(3 * 0.02)
      end
      if @controls.backward?
        walk(-3 * 0.02)
      end
      if @controls.strafe_left?
        strafe(-3 * 0.01)
      end
      if @controls.strafe_right?
        strafe(3 * 0.01)
      end
      if @controls.left?
        rotate(-Math::PI * 0.01)
      end
      if @controls.right?
        rotate(Math::PI * 0.01)
      end
    end

    private def walk(distance)
      dx = Math.sin(@direction) * distance
      dy = -Math.cos(@direction) * distance
      @x += dx if @map.get(@x + dx, @y) <= 0
      @y += dy if @map.get(@x, @y + dy) <= 0
    end

    private def strafe(distance)
      dx = Math.sin(@direction + Math::PI/2) * distance
      dy = -Math.cos(@direction + Math::PI/2) * distance
      @x += dx if @map.get(@x + dx, @y) <= 0
      @y += dy if @map.get(@x, @y + dy) <= 0
    end

    private def rotate(angle)
      @direction = (direction + angle + 2*Math::PI) % (2*Math::PI)
    end
  end
end
