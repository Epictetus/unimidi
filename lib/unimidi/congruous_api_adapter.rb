#!/usr/bin/env ruby
#

module UniMIDI

  module CongruousApiAdapter

    module Device
      
      def initialize(device_obj)        
        @device = device_obj
        @id = @device.id
        @name = @device.name
        @type = @device.type
      end

      # enable the device for use, can be passed a block to which the device will be passed back
      def open(*a, &block)
        @device.open(*a)
        unless block.nil?
          begin
            yield(self)
          ensure
            close
          end
        else
        self
        end
      end

      # close the device
      def close(*a)
        @device.close(*a)
      end

      def self.included(base)
        base.send(:attr_reader, :name)
        base.send(:attr_reader, :id)
        base.send(:attr_reader, :type)
      end

      module ClassMethods
        
        # returns the first device for this class
        def first(*a)
          dev = @deference[self].first(*a)
          raise 'Device not found' if dev.nil?
          new(dev)
        end

        # returns the last device for this class
        def last(*a)
          dev = @deference[self].last(*a)
          raise 'Device not found' if dev.nil?
          new(dev)          
        end

        # returns all devices in an array
        def all
          all_by_type.values.flatten
        end

        # returns all devices as a hash as such
        #   { :input => [input devices], :output => [output devices] }
        def all_by_type
          {
            :input => @deference[self].all_by_type[:input].map { |d| @input_class.new(d) },
            :output => @deference[self].all_by_type[:output].map { |d| @output_class.new(d) }
          }
        end

        def defer_to(klass)
          @deference ||= {}
          @deference[self] = klass
        end

        def input_class(klass)
          @input_class = klass
        end

        def output_class(klass)
          @output_class = klass
        end

      end

    end

  end

  class CongruousApiInput
    
    include CongruousApiAdapter::Device
    extend CongruousApiAdapter::Device::ClassMethods
    extend Forwardable
    
    def_delegators :@device, :buffer
    
    #
    # returns an array of MIDI event hashes as such:
    #   [
    #     { :data => [144, 60, 100], :timestamp => 1024 },
    #     { :data => [128, 60, 100], :timestamp => 1100 },
    #     { :data => [144, 40, 120], :timestamp => 1200 }
    #   ]
    #
    # the data is an array of Numeric bytes
    # the timestamp is the number of millis since this input was enabled
    #
    def gets(*a)
      @device.gets(*a)
    end

    #
    # same as gets but returns message data as string of hex digits as such:
    #   [
    #     { :data => "904060", :timestamp => 904 },
    #     { :data => "804060", :timestamp => 1150 },
    #     { :data => "90447F", :timestamp => 1300 }
    #   ]
    #
    def gets_s(*a)
      @device.gets_s(*a)
    end
    alias_method :gets_bytestr, :gets_s
    alias_method :gets_hex, :gets_s

    #
    # returns an array of data bytes such as
    #   [144, 60, 100, 128, 60, 100, 144, 40, 120]
    #
    def gets_data(*a)
      arr = gets
      arr.map { |msg| msg[:data] }.inject { |a,b| a + b }
    end

    #
    # returns a string of data such as
    #   "90406080406090447F"
    #
    def gets_data_s(*a)
      arr = gets_bytestr
      arr.map { |msg| msg[:data] }.join
    end
    alias_method :gets_data_bytestr, :gets_data_s
    alias_method :gets_data_hex, :gets_data_s
    
    # clears the buffer
    def clear_buffer
      @device.buffer.clear
    end
    
    # gets any messages in the buffer in the same format as CongruousApiInput#gets 
    def gets_buffer(*a)
      @device.buffer
    end
    
    # gets any messages in the buffer in the same format as CongruousApiInput#gets_s
    def gets_buffer_s(*a)
      @device.buffer.map { |msg| msg[:data] = TypeConversion.numeric_byte_array_to_hex_string(msg[:data]); msg }
    end
    
    # gets any messages in the buffer in the same format as CongruousApiInput#gets_data
    def gets_buffer_data(*a)
      @device.buffer.map { |msg| msg[:data] }
    end

    # returns all inputs
    def self.all
      @deference[self].all.map { |d| new(d) }
    end

  end

  class CongruousApiOutput
    
    include CongruousApiAdapter::Device
    extend CongruousApiAdapter::Device::ClassMethods
    
    # sends a message to the output. the message can be:
    #
    # bytes eg output.puts(0x90, 0x40, 0x40)
    # an array of bytes eg output.puts([0x90, 0x40, 0x40])
    # or a string eg output.puts("904040")
    #
    def puts(*a)
      @device.puts(*a)
    end

    # sends a message to the output in a form of a string eg "904040".  this method does not do
    # type checking and therefore is more performant than puts
    def puts_s(*a)
      @device.puts_s(*a)
    end
    alias_method :puts_bytestr, :puts_s
    alias_method :puts_hex, :puts_s

    # sends a message to the output in a form of bytes eg output.puts_bytes(0x90, 0x40, 0x40).
    # this method does not do type checking and therefore is more performant than puts
    def puts_bytes(*a)
      @device.puts_bytes(*a)
    end

    # returns all outputs
    def self.all
      @deference[self].all.map { |d| new(d) }
    end

  end

  class CongruousApiDevice
    extend CongruousApiAdapter::Device::ClassMethods
  end

end