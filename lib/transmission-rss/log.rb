require( 'singleton' )

class TransmissionRSS::Log
	include Singleton

	attr_accessor :target, :verbose
	
	def add( *args )
		@buffer ||= []

		# Add every arg to buffer.
		args.each do |arg|
			@buffer.push( arg.to_s )
		end
	end

	def run
		@target ||= $stderr
		@buffer ||= []

		# If verbose is not defined, it will be nil.
		@verbose = (@verbose rescue nil)

		# If +@target+ seems to be a file path, open the file and tranform
		# +@target+ into an IO for the file.
		if( @target.class != IO and @target.match( /(\/.*)+/ ) )
			@target = File.open( @target, 'a' )
			@target.sync = true

			@verbose = true
		end

		# Loop, pop buffer and puts.
		while( true )
			line = @buffer.shift

			if( @verbose and line )
				@target.puts( line )
			end

			sleep( 0.1 )
		end
	end
end
