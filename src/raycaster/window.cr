module Raycaster
  class Window
    getter :resolution

    @controls : Controls
    @map : Map
    @player : Player
    @camera : Camera?
    # @hud : Hud?

    def initialize
      @resolution = { x: 1280, y: 960 }
      @window = SF::RenderWindow.new(
        SF::VideoMode.new(@resolution[:x], @resolution[:y]),
        "Float",#"Raycaster",
        settings: SF::ContextSettings.new(depth: 24, antialiasing: 8)
      )
      @window.vertical_sync_enabled = true
      @controls = Controls.new
      @map = Map.new
      @player = Player.new(@controls, @map)
      @camera = camera = Camera.new(self, @map, @player)
      # @hud = Hud.new(self, @map, @player, camera)
    end

    def update
      @player.update
    end

    def draw
      @window.clear(SF::Color::Black)
      @camera.try(&.draw())
      # @hud.try(&.draw())
      @window.display
    end

    def draw_entity(entity)
      @window.draw(entity)
    end

    def draw_quad(x1, y1, c1, x2, y2, c2, x3, y3, c3, x4, y4, c4)
      convex = SF::ConvexShape.new
      convex.fill_color = c4
      convex.point_count = 4
      convex[0] = SF.vector2(x1, y1)
      convex[1] = SF.vector2(x2, y2)
      convex[3] = SF.vector2(x3, y3)
      convex[2] = SF.vector2(x4, y4)
      draw_entity(convex)
    end

    def get_fps(time)
      1_000_000 / time.as_microseconds()
    end

    def run

      fps_clock = SF::Clock.new

      while @window.open?
        while event = @window.poll_event
          # "close requested" event: we close the window
          if event.is_a? SF::Event::Closed
            @window.close
          end

          # catch the resize events
          # if event.is_a? SF::Event::Resized
          #   # update the view to the new size of the window
          #   visible_area = SF.float_rect(0, 0, event.width, event.height)
          #   window.view = SF::View.new(visible_area)
          # end
        end

        update()
        draw()

        puts get_fps(fps_clock.restart())
      end
    end
  end
end
