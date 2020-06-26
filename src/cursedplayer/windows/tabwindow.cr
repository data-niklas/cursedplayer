require "ncurses"

module CursedPlayer
  class TabBar < NCurses::EventWindow
    @tabs = [] of Tab

    property selected
    getter tabs

    def initialize(@selected : Int32 = 0)
      initialize(1, CursedPlayer.w, 2, 0)
      track
    end

    def update_size
      resize 1, CursedPlayer.w
      @tabs.each do |tab|
        tab.resize CursedPlayer.h - 4, CursedPlayer.w
        tab.render
      end
      render
    end

    def add_tab(tab)
      @tabs << tab
      if @tabs.size - 1 == @selected
        tab.select
        render
      end
    end

    def mouse_pressed(state, x, y, z, device_id)
      if !CursedPlayer.popup
        if (state.value > NCurses::Mouse::Position.value || state == NCurses::Mouse::B1Clicked || state == NCurses::Mouse::B1Pressed)   
          offset = x - (x % @tabs.size)
          old = @selected
          @selected = (offset / @tabs.size).to_i
          if @selected < @tabs.size
            @tabs[old].unselect
            @tabs[@selected].select
            render
          end
        end
      end
    end


    def render_tab()
      if @selected < @tabs.size
        @tabs[@selected].render
      end
    end

    def render()
      clear
      @tabs.each_with_index do |tab, index|
        if index == selected
          attr_on NCurses::Attribute::Standout
          attr_on NCurses::Attribute::Bold
        end
        print tab.name, 0, index*@tabs.size
        if index == selected
          attr_off NCurses::Attribute::Standout
          attr_off NCurses::Attribute::Bold
        end
      end
      refresh
    end

    def event(tab_name : String, name : String, subevent : String = "", data : Int32 | Player::Media = 0)
      @tabs.each do |tab|
        if tab.name == tab_name
          tab.event name, subevent, data
        end
      end
    end
  end

  abstract class Tab < NCurses::EventWindow
    getter name

    def initialize(@name : String)
      initialize(CursedPlayer.h - 4, CursedPlayer.w, 3, 0)
      @visible = false
      track
    end

    abstract def render()
    abstract def select
    abstract def unselect
    abstract def event(name : String, subevent : String, data : Int32 | Player::Media)


  end
end
