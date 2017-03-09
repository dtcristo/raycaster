module Raycaster
  class Controls
    def up?
      Gosu.button_down?(Gosu::KB_UP) || Gosu::button_down?(Gosu::GP_UP) ||
        Gosu::button_down?(Gosu::GP_BUTTON_0)
    end

    def down?
      Gosu.button_down?(Gosu::KB_DOWN) || Gosu::button_down?(Gosu::GP_DOWN)
    end

    def left?
      Gosu.button_down?(Gosu::KB_LEFT) || Gosu::button_down?(Gosu::GP_LEFT)
    end

    def right?
      Gosu.button_down?(Gosu::KB_RIGHT) || Gosu::button_down?(Gosu::GP_RIGHT)
    end
  end
end
