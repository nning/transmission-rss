# http://www.lakeinfoworks.com/blog/wp-content/listbox.rb
class TransmissionRSS::ListBox < Gtk::ScrolledWindow
	def initialize
		super

		tbl = Gtk::Table.new( 2, 2, false )

		self.hscrollbar_policy = Gtk::PolicyType::AUTOMATIC
		self.vscrollbar_policy = Gtk::PolicyType::AUTOMATIC
		self.shadow_type = Gtk::ShadowType::NONE
		self.window_placement= Gtk::CornerType::TOP_LEFT

		@renderer = Gtk::CellRendererText.new

#		@renderer.set_property( 'background', 'lavender' )
		@renderer.set_property( 'background', 'white' )
		@renderer.set_property( 'foreground', 'black' )

		@list_store = Gtk::ListStore.new( String )
		@tree_view = Gtk::TreeView.new( @list_store )

		@tree_view_col1 = Gtk::TreeViewColumn.new( '', @renderer, { :text => 0 } )
		@tree_view_col1.sizing = Gtk::TreeViewColumn::AUTOSIZE

		@text_col = 0

		@tree_view.append_column( @tree_view_col1 )
		@tree_view.headers_visible = false
		@tree_view.selection.mode = Gtk::SELECTION_SINGLE

		tbl.attach_defaults( @tree_view, 0, 2, 0, 2 )

		self.add_with_viewport(tbl)
	end

	def add( *args )
		args.each do |arg|
			arg = arg.first if( arg.class == Array ) # TODO ?!
			iter = @list_store.append
			iter.set_value( 0, arg.to_s )
		end
	end

	def button_release( widget, event, type = 'text' )
		path, column, cell_x, cell_y = @tree_view.get_path_at_pos( event.x, event.y )

		return( '' ) if( column.nil? )

		entry = case( type )
			when 'line_nbr'
				path
			when 'text'
				@tree_view.selection.selected[@tree_view.columns.index( column )]
		end

		return( entry )
	end

	def clear
		@list_store.clear
	end

	def header=( string )
		@tree_view.headers_visible = true
		@tree_view_col1.title = string
	end

	# TODO produces Gtk-CRITICAL
	def remove( *args )
		args.each do |arg|
			iter = @list_store.iter_first

			begin
				if( iter.get_value( 0 ) == arg )
					@list_store.remove( iter )
				end
			end while( iter.next! )
		end
	end

	def items
		array = []

		iter = @list_store.iter_first

		if( not iter.nil? )
			begin
				array << iter.get_value( 0 )
			end while( iter.next! )
		end

		array
	end
end
