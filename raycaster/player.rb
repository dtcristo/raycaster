module Raycaster
  class Player
    attr_reader :x, :y, :direction

    def initialize(controls, map)
      @controls = controls
      @map = map
      spawn_point = map.spawn_point
      @x = spawn_point[:x]
      @y = spawn_point[:y]
      @direction = spawn_point[:direction]
    end

    def update
      if @controls.forward?
        walk(3 * 0.04)
      end
      if @controls.backward?
        walk(-3 * 0.04)
      end
      if @controls.strafe_left?
        strafe(-3 * 0.02)
      end
      if @controls.strafe_right?
        strafe(3 * 0.02)
      end
      if @controls.left?
        rotate(-Math::PI * 0.02)
      end
      if @controls.right?
        rotate(Math::PI * 0.02)
      end
    end

    private

    def walk(distance)
      dx = Math.sin(@direction) * distance
      dy = -Math.cos(@direction) * distance
      @x += dx if @map.get(@x + dx, @y) <= 0
      @y += dy if @map.get(@x, @y + dy) <= 0
    end

    def strafe(distance)
      dx = Math.sin(@direction + Math::PI/2) * distance
      dy = -Math.cos(@direction + Math::PI/2) * distance
      @x += dx if @map.get(@x + dx, @y) <= 0
      @y += dy if @map.get(@x, @y + dy) <= 0
    end

    def rotate(angle)
      @direction = (direction + angle + 2*Math::PI) % (2*Math::PI)
    end
  end
end
