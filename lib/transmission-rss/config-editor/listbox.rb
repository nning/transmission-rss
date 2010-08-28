#     ListBox - A GTK Listbox
#--
###################################################################################
#
#     ListBox - A GTK Listbox
#     Copyright (C) 2007  Lake Information Works
# 
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
# 
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
#     Contact: alan.lake AT lakeinfoworks DOT com
#              Lake Information Works
#              Kalervonkatu 13 A 2 
#              20400 Jyväskylä
#              Finland
# 
###################################################################################
#++
=begin rdoc
Sample usage
  Gtk.init
  @main_window = Gtk::Window.new
  @main_window.set_default_size 500,300
  lb_left = ListBox.new
  lb_left.header = 'Ad Groups'
  lb_left.append('ulkomaanpuhelut')
  lb_left.append('kaukopuhelut')
  lb_left.append('suuntanumerot')
  lb_right = ListBox.new
  lb_right.header = 'State Nicknames'
  lb_right.fill(['Empire','Golden','Silver','Sooner','Hoosier','Razorback','Buckeye','Lone Star'])
  box = Gtk::HBox.new
  @main_window.add(box)
  box.pack_start(lb_left,true)
  box.pack_start(lb_right,true)
  @main_window.show_all
  @main_window.signal_connect("destroy") { Gtk.main_quit }
  lb_left.signal_connect('button_release_event') do |widget,event|
    puts lb_left.button_release(widget,event)
    end
  lb_left.signal_connect('key-release-event') do |widget,event|
    selection = lb_left.key_release(widget,event)
    puts "#{selection}" if selection.class == String
    end
# Note that no signal_connect code has been written for lb_right, so a selection cannot be made.
  Gtk.main
=end
=begin rdoc
Purpose:
  1. Document how to create a GTK widget in Ruby.
  2. Create a general purpose listbox.
Credit:
  Mathieu Blondel responded to my post on the Ruby Forum to teach me how to
  create a valid widget.  http://www.ruby-forum.com/topic/126951
Assumptions:
  This document doesn't attempt to teach Ruby or GTK programming (or the
  combination.  Therefore, we assume that the reader knows how to create a
  Ruby Class.
What's a widget? 
  http://www.webopedia.com/TERM/W/widget.html defines a widget.  The listbox shown
  here provides a way for the user to interface with an application by using the 
  mouse or keyboard to select an item in the list, whereupon the listbox 
  communicates the selection to the application.
What is provided here:
  The following is in two parts: The class that creates the listbox widget and a
  piece of code that illustrates the use of it.  I will include comments in the 
  code that shows what needs to be done to make a class into a widget, but will
  not completely comment the code.  I am commenting the parts involved with
  inheritance because it is the inheritance that makes ListBox a widget.

  This listbox is extremely basic.  The minimalistic design meets my need for a 
  listbox and makes it easier to highlight what it is that makes it a widget.
  Furthermore, the fact that it is basic will allow me or another programmer to 
  easily modify it to include more sophisticated features.
=end
=begin rdoc
ListBox inherits Gtk::ScrolledWindow.  ScrolledWindow was chosen because 
  (1) ScrolledWindow is a widget.  This fact can be shown with interactive ruby
      (irb) by doing (a) or (b):
      (a)
        [alan@erie ~]$ irb
        irb(main):001:0> require 'gtk2'
        => true
        irb(main):002:0> sw = Gtk::ScrolledWindow.new
        => #<Gtk::ScrolledWindow:0x2aaab008d088 ptr=0xac4bd0>
        irb(main):003:0> sw.is_a? Gtk::Widget
        => true
      (b)
        [alan@erie ~]$ irb
        irb(main):001:0> require 'gtk2'
        => true
        irb(main):002:0> Gtk::ScrolledWindow.ancestors
        => [Gtk::ScrolledWindow, Gtk::Bin, Gtk::Container, Gtk::Widget, Atk::Implementor, GLib::Interface, GLib::MetaInterface, Gtk::Object, GLib::InitiallyUnowned, GLib::Object, GLib::Instantiatable, Object, Kernel]
      Note that Gtk::Widget is among ScrolledWindow's ancestors.
  (2) the scrolled window part of this widget is the part that the user adds
      to the GUI application. 
=end
class ListBox < Gtk::ScrolledWindow
=begin rdoc
  "super()" is needed because the Listbox class is inherited.
  "self" refers to the ListBox, but because ListBox inherits ScrolledWindow, references to this scrolled window are also made with "self".
=end
  def initialize
    super() 

    tbl = Gtk::Table.new(2,2,false) # 2 rows, 2 columns, not homogeneous
    self.hscrollbar_policy = Gtk::PolicyType::AUTOMATIC
    self.vscrollbar_policy = Gtk::PolicyType::AUTOMATIC
    self.shadow_type = Gtk::ShadowType::NONE
    self.window_placement= Gtk::CornerType::TOP_LEFT

    @renderer=Gtk::CellRendererText.new
    @renderer.set_property( 'background', 'lavender' )
    @renderer.set_property( 'foreground', 'black' )

    @list_store  = Gtk::ListStore.new(String)
    @tree_view = Gtk::TreeView.new(@list_store)

    col_hdr = ''
    @tree_view_col1 = Gtk::TreeViewColumn.new(col_hdr, @renderer, {:text => 0})
    @tree_view_col1.sizing = Gtk::TreeViewColumn::AUTOSIZE
    @text_col = 0
    @tree_view.append_column(@tree_view_col1)
    @tree_view.headers_visible = false
    @tree_view.selection.mode = Gtk::SELECTION_SINGLE

    tbl.attach_defaults(@tree_view,0,2,0,2) # widget, left, right, top, bottom
    self.add_with_viewport(tbl)
  end # def initialize

=begin rdoc
Appends a string to ListBox's list.
=end
  def append(str)
    iter = @list_store.append
    iter.set_value(0, str)
  end

=begin rdoc
This is a significant part of the widget, providing communication from it to the application.
Called by a signal connect mouse button_release_event:
  lb_left.signal_connect('button_release_event') do |widget,event|
    puts lb_left.button_release(widget,event)
    end
Returns: The string that is selected.
=end
  def button_release(widget,event,type='text')
    path, column, cell_x, cell_y = @tree_view.get_path_at_pos(event.x, event.y)
    return path if type == 'line_nbr'
    @tree_view.selection.selected[@tree_view.columns.index(column)] if type == 'text'
  end

=begin rdoc
Clears the ListBox's list
=end
  def clear
    @list_store.clear
  end

=begin rdoc
Fills the ListBox's list from the array of "items".
=end
  def fill(items)
    items.each { |item| self.append(item) }
  end

=begin rdoc
Provides a header for the list.
=end
  def header=(hdr)
    @tree_view.headers_visible = true unless @tree_view.headers_visible?
    @tree_view_col1.title = hdr
  end

=begin rdoc
This is a significant part of the widget, providing communication from it to the application.
Called by a signal connect key_release_event, which occurs when the user uses keys to navigate:
  lb_left.signal_connect('key-release-event') do |widget,event|
    selection = lb_left.key_release(widget,event)
    puts "#{selection}" if selection.class == String
    end
Returns: Selected string if the Enter or Return key is pressed; nil if any other key is pressed.  The up and down keys navigate the list.
=end
  def key_release(widget,event)
    return nil unless event.keyval == 65293 # Enter
    column = @tree_view.get_column(0)
    @tree_view.selection.selected[@tree_view.columns.index(column)]
  end

=begin rdoc
Select the item in the list that is equal to text
=end
  def select(text)
    iter = @list_store.iter_first
    begin
      if iter[@text_col] == text
        @tree_view.selection.select_iter(iter) 
        return true
      end
    end while iter.next!
    return false
  end

=begin rdoc
Synonym for the header=(hdr) method.
=end
  def set_header(hdr)
    self.header = hdr
  end

=begin rdoc
Returns the text of line <nbr>.
=end
  def text_at_line(nbr)
    iter = @list_store.iter_first
    line_nbr = 0
    begin
      return iter.get_value(@text_col) if line_nbr == nbr
      line_nbr += 1
    end while iter.next!
    return []
  end
end
