# Represents the config editor window.
class TransmissionRSS::ConfigEditor
	TITLE = 'transmission-rss config editor'
	NAME = 'config-editor'

	# Loads glade file and initializes dynamic GUI elements.
	def initialize( configFile, config )
		@configFile = configFile
		@config = config

		path = File.join( File.dirname( __FILE__ ), 'main.glade' )

		# Load glade file and connect to handler method. Dubious.
		@glade = GladeXML.new( path ) do |handler|
			method( handler )
		end

		# Connect every widget to an instance variable.
		@glade.widget_names.each do |name|
			name.gsub!( /-/, '_' )
			instance_variable_set( "@#{name}".intern, @glade[name] )
		end

		# Quit program, when it is closed by the WM.
		@window1.signal_connect( 'destroy' ) do
			Gtk.main_quit
		end

		# Initialize the ListBox widget.
		initialize_listbox

		# Reflect the current config on the GUI.
		initialize_config
	end

	# Reflects the current config on the GUI.
	def initialize_config
		@entry_server_host.text = @config.server.host
		@entry_server_port.text = @config.server.port.to_s

		@entry_update_interval.text = @config.update_interval.to_s

		@checkbutton_add_paused.active = @config.start_paused

		@listbox.add( @config.feeds )

		# If log target is STDERR.
		if( @config.log_target.class == IO )
			# Deactivate log path entry.
			@label10.sensitive = false
			@entry_log_filepath.sensitive = false

			@combobox_logtype.active = 0
		else
			# Activate log path entry.
			@label10.sensitive = true
			@entry_log_filepath.sensitive = true

			# Set entry text accordingly.
			@entry_log_filepath.text = @config.log_target

			@combobox_logtype.active = 1
		end
	end

	# Initializes the ListBox widget.
	def initialize_listbox
		@listbox = ListBox.new
		@listbox.header = 'Feeds'

		@vbox2.pack_start( @listbox )

		@window1.show_all

		@listbox.signal_connect( 'button_release_event' ) do |widget, event|
			@entry_feed_url.text = @listbox.button_release( widget, event )
		end
	end

	# Add a feed to the ListBox if the Add-feed-button is pressed.
	def on_button_add_feed( widget )
		if( not @entry_feed_url.text.empty? )
			@listbox.add( @entry_feed_url.text )
			@entry_feed_url.text = ''
		end
	end

	# Remove a feed from the ListBox if the Remove-feed-button is pressed.
	def on_button_remove_feed( widget )
		@listbox.remove( @entry_feed_url.text )
	end

	# Is called when a value in the log type ComboBox is selected.
	def on_combobox_logtype_changed( widget )
		# If STDERR is selected.
		if( @combobox_logtype.active == 0 )
			# Deactivate the log file path entry.
			@label10.sensitive = false
			@entry_log_filepath.sensitive = false

			@entry_log_filepath.text = ''
		else
			# Activate the log file path entry.
			@label10.sensitive = true
			@entry_log_filepath.sensitive = true
		end
	end

	# Is called when the File-Save menu is selected.
	def on_menu_save( widget )
		@config.server.host = @entry_server_host.text
		@config.server.port = @entry_server_port.text.to_i

		@config.update_interval = @entry_update_interval.text.to_i

		@config.start_paused = @checkbutton_add_paused.active?

		@config.feeds = @listbox.items

		# If STDERR is selected.
		if( @combobox_logtype.active == 0 )
			# Delete log_target from config hash, so $stderr is chosen on load.
			@config.delete( 'log_target' )
		else
			# Set log_target to entry text.
			@config.log_target = @entry_log_filepath.text
		end

		save!
	end

	# Is called when the File-SaveAs menu is selected.
	def on_menu_save_as( widget )
		dialog = Gtk::FileChooserDialog.new(
			"Save As..",
			@window1,
			Gtk::FileChooser::ACTION_SAVE,
			nil,
			[Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
			[Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT]
		)

		if( dialog.run == Gtk::Dialog::RESPONSE_ACCEPT )
			@configFile = dialog.filename
		end

		dialog.destroy

		save!
	end

	# Is called when the File-Quit menu is selected.
	def on_menu_quit( widget )
		Gtk.main_quit
	end

	# Open the config file and write a YAML version of the Hash.
	def save!
		File.open( @configFile, 'w' ) do |f|
			f.write( @config.to_yaml )
		end
	rescue Errno::EACCES
		dialog = Gtk::MessageDialog.new(
			@window1, 
			Gtk::Dialog::DESTROY_WITH_PARENT,
			Gtk::MessageDialog::ERROR,
			Gtk::MessageDialog::BUTTONS_CLOSE,
			"Permission denied:\n" + @configFile
		)

		dialog.run
		dialog.destroy	
	end
end
