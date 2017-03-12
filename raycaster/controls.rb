module Raycaster
  class Controls
    
    # Button mapping for 8Bitdo SFC30 GamePad
    # Gosu::GP_BUTTON_0  -> B
    # Gosu::GP_BUTTON_1  -> A
    # Gosu::GP_BUTTON_2  -> Y
    # Gosu::GP_BUTTON_3  -> X
    # Gosu::GP_BUTTON_4  -> SELECT
    # Gosu::GP_BUTTON_6  -> START
    # Gosu::GP_BUTTON_9  -> L
    # Gosu::GP_BUTTON_10 -> R

    def forward?
      Gosu.button_down?(Gosu::KB_UP) ||
      Gosu.button_down?(Gosu::KB_W) ||
      Gosu.button_down?(Gosu::GP_UP) ||
      Gosu.button_down?(Gosu::GP_BUTTON_1)
    end

    def backward?
      Gosu.button_down?(Gosu::KB_DOWN) ||
      Gosu.button_down?(Gosu::KB_S) ||
      Gosu.button_down?(Gosu::GP_DOWN) ||
      Gosu.button_down?(Gosu::GP_BUTTON_0)
    end

    def strafe_left?
      Gosu.button_down?(Gosu::KB_A) ||
      Gosu.button_down?(Gosu::GP_BUTTON_9)
    end

    def strafe_right?
      Gosu.button_down?(Gosu::KB_D) ||
      Gosu.button_down?(Gosu::GP_BUTTON_10)
    end

    def left?
      Gosu.button_down?(Gosu::KB_LEFT) ||
      Gosu.button_down?(Gosu::KB_Q) ||
      Gosu.button_down?(Gosu::GP_LEFT)
    end

    def right?
      Gosu.button_down?(Gosu::KB_RIGHT) ||
      Gosu.button_down?(Gosu::KB_E) ||
      Gosu.button_down?(Gosu::GP_RIGHT)
    end
  end
end
