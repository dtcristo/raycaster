module Raycaster
  class Map
    attr_reader :size

# Coordinate system:
#
#    θ=0°
#     △
#     ┆
#     ┌──────▶ x+
#     │
#     │
#     ▼
#     y+
#
#   x_comp = sin(θ)
#   y_comp = -cos(θ)

    def initialize
      @size = 10
      @grid = [
        [1,0,1,1,1,1,1,1,1,1],
        [1,0,1,0,0,0,0,0,0,1],
        [1,0,0,0,1,0,0,0,0,1],
        [1,1,0,1,1,0,0,0,0,1],
        [1,0,0,0,1,1,1,1,0,1],
        [1,0,0,0,1,0,0,0,0,1],
        [1,0,1,0,1,0,0,0,0,1],
        [1,0,0,0,1,0,1,1,1,1],
        [1,0,0,0,1,0,0,0,0,0],
        [1,1,1,1,1,1,1,1,0,1],
      ]
    end

    def spawn_point
      { x: 8.5, y: 11.5, direction: 0 }
    end

    def get(x, y)
      x = x.floor
      y = y.floor
      if x < 0 || x > @size - 1 || y < 0 || y > @size - 1
        -1 # Outside of grid
      else
        @grid[y][x]
      end
    end
  end
end
