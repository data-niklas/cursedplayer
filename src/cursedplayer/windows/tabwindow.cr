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
      end
      render
      render_tab
    end

    def add_tab(tab)
      @tabs << tab
      if @tabs.size - 1 == @selected
        tab.select
        render
      end
    end

    def mouse_pressed(event, x, y, z)
      if !CursedPlayer.popup
        if event.state_includes? NCurses::Mouse::B1Clicked   
          old = @selected
          index = 0
          cx = 0
          separator_length = CursedPlayer.conf["tab_separator"].to_s.size
          w = self.width
          while cx < w && index < @tabs.size
            cx += @tabs[index].name.size + separator_length
            if x < cx
              @selected = index
              break
            end
            index+=1
          end

          if old != @selected && @selected < @tabs.size
            @tabs[old].unselect
            @tabs[@selected].select
            render
            @tabs[@selected].render
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
        print tab.name
        if index == selected
          attr_off NCurses::Attribute::Standout
          attr_off NCurses::Attribute::Bold
        end
        print CursedPlayer.conf["tab_separator"].to_s
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
