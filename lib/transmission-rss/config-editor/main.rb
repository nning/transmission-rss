class TransmissionRSS::ConfigEditor
	TITLE = 'transmission-rss config editor'
	NAME = 'config-editor'

	def initialize( config )
		@config = config

		path = File.join( File.dirname( __FILE__ ), 'main.glade' )

		@glade = GladeXML.new( path ) do |handler|
			method( handler )
		end

		@glade.widget_names.each do |name|
			name.gsub!( /-/, '_' )
			instance_variable_set( "@#{name}".intern, @glade[name] )
		end

		@window1.signal_connect( 'destroy' ) do
			Gtk.main_quit
		end

		@entry_feed_url.activates_default = true

		initialize_config
		initialize_listbox
	end

	def initialize_config
		@entry_server_host.text = @config.server.host
		@entry_server_port.text = @config.server.port.to_s

		@entry_update_interval.text = @config.update_interval.to_s

		@checkbutton_add_paused.active = @config.start_paused
	end

	def initialize_listbox
		@listbox = ListBox.new
		@listbox.header = 'Feeds'

		@listbox.add( @config.feeds )

		@vbox2.pack_start( @listbox )

		@window1.show_all

		@listbox.signal_connect( 'button_release_event' ) do |widget, event|
			@entry1.text = @listbox.button_release( widget, event )
		end

#		@listbox.signal_connect( 'key-release-event' ) do |widget, event|
#			selection = @listbox.key_release( widget, event )
#			puts "#{selection}" if selection.class == String
#		end
	end

	def on_button_add_feed( widget )
		if( not @entry1.text.empty? )
			@listbox.add( @entry1.text )
			@entry1.text = ''
		end
	end

	def on_button_remove_feed( widget )
		@listbox.remove( @entry1.text )
	end

	def on_button_save( widget )
		@config.server.host = @entry_server_host.text
		@config.server.port = @entry_server_port.text.to_i

		@config.update_interval = @entry_update_interval.text.to_i

		@config.start_paused = @checkbutton_add_paused.active?

		p @config
	end

	def on_menu_quit( widget )
		Gtk.main_quit
	end

	def on_menu_about( widget )
		Gnome::About.new(
			TITLE,
			VERSION,
			'Copyright 2010 (c) henning mueller',
			'Config editor for transmission-rss.',
			['henning mueller'],
			['henning mueller'],
			nil
		).show
	end
end
