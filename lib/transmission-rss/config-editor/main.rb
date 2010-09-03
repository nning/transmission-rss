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

		initialize_listbox

		initialize_config
	end

	def initialize_config
		@entry_server_host.text = @config.server.host
		@entry_server_port.text = @config.server.port.to_s

		@entry_update_interval.text = @config.update_interval.to_s

		@checkbutton_add_paused.active = @config.start_paused

		# If log target is STDERR.
		if( @config.log_target.class == IO )
			@label10.sensitive = false
			@entry_log_filepath.sensitive = false

			@combobox_logtype.active = 0
		else
			@label10.sensitive = true
			@entry_log_filepath.sensitive = true

			@combobox_logtype.active = 1

			@entry_log_filepath.text = @config.log_target
		end

		@listbox.add( @config.feeds )
	end

	def initialize_listbox
		@listbox = ListBox.new
		@listbox.header = 'Feeds'

		@vbox2.pack_start( @listbox )

		@window1.show_all

		@listbox.signal_connect( 'button_release_event' ) do |widget, event|
			@entry_feed_url.text = @listbox.button_release( widget, event )
		end
	end

	def on_button_add_feed( widget )
		if( not @entry_feed_url.text.empty? )
			@listbox.add( @entry_feed_url.text )
			@entry_feed_url.text = ''
		end
	end

	def on_button_remove_feed( widget )
		@listbox.remove( @entry_feed_url.text )
	end

	def on_combobox_logtype_changed( widget )
		# If STDERR is selected.
		if( @combobox_logtype.active == 0 )
			@label10.sensitive = false
			@entry_log_filepath.sensitive = false

			@entry_log_filepath.text = ''
		else
			@label10.sensitive = true
			@entry_log_filepath.sensitive = true
		end
	end

	def on_menu_save( widget )
		@config.server.host = @entry_server_host.text
		@config.server.port = @entry_server_port.text.to_i

		@config.update_interval = @entry_update_interval.text.to_i

		@config.start_paused = @checkbutton_add_paused.active?

		@config.feeds = @listbox.items

		# If STDERR is selected.
		if( @combobox_logtype.active == 0 )
			@config.delete( 'log_target' )
		else
			@config.log_target = @entry_log_filepath.text
		end

		puts( @config.to_yaml )
	end

	def on_menu_quit( widget )
		Gtk.main_quit
	end
end
