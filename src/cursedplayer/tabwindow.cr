require "ncurses"

module CursedPlayer
  class TabWindow < NCurses::Window
    @tabs = [] of Tab

    property selected
    getter tabs

    def initialize(h : Int32, w : Int32, y : Int32 = 0, x : Int32 = 0, @tab_size : Int32 = 8, @selected : Int32 = 0)
      initialize(LibNCurses.newwin(h, w, y, x))
    end

    def add_tab(tab, update = false)
      @tabs << tab
      if update
        repaint
      end
    end

    def tab_click(x : Int32)
      offset = x - (x % @tab_size)
      @selected = (offset / @tab_size).to_i
      if @selected < @tabs.size
        @tabs[@selected].select
        repaint
      end
    end

    def content_click(y : Int32, x : Int32)
      if @selected < @tabs.size
        @tabs[@selected].mouse_press y - self.y, x
      end
    end

    def repaint()
      clear
      @tabs.each_with_index do |tab, index|
        if index == selected
          attr_on NCurses::Attribute::Standout
          attr_on NCurses::Attribute::Bold
        end
        print tab.name, 0, index*@tab_size
        if index == selected
          attr_off NCurses::Attribute::Standout
          attr_off NCurses::Attribute::Bold
        end
      end
      if @selected < @tabs.size
        @tabs[@selected].render self, width(), height() - 1
      end
      refresh
    end
  end

  abstract class Tab
    @scrollable = false
    @scroll_y = 0
    getter name

    def initialize(@name : String, @scrollable)
    end

    abstract def render(ui : NCurses::Window, w : Int32, h : Int32)
    abstract def select_item(index, pos)
    abstract def scroll(up = true)
    abstract def select
    abstract def rerender?(queue_index : Int32, w : Int32, h : Int32)

    def mouse_press(y, x)
      if @scrollable
        y += @scroll_y
      end
      select_item(y - 1, x)
    end
  end
end
