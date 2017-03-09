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
      if @controls.up?
        walk(3 * 0.05)
      end
      if @controls.down?
        walk(-3 * 0.05)
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
      dx = Math.cos(@direction) * distance
      dy = Math.sin(@direction) * distance
      @x += dx if @map.get(@x + dx, @y) <= 0
      @y += dy if @map.get(@x, @y + dy) <= 0
    end

    def rotate(angle)
      @direction = (direction + angle + 2*Math::PI) % (2*Math::PI)
    end
  end
end
