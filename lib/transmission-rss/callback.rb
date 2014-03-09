module TransmissionRSS
  module Callback
    # Define callback method.
    def callback(*names)
      names.each do |name|
        self.class_eval do
          define_method name, ->(*args, &block) do
            @callbacks ||= {}
            if block
              @callbacks[name] = block
            elsif @callbacks[name]
              @callbacks[name].call *args
            end
          end
        end
      end
    end
  end
end
