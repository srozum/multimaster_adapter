require 'rubygems'
gem 'activerecord', '<= 2.0.0'
require 'active_record'
require 'active_record/connection_adapters/abstract_adapter'

module ActiveRecord
  
  class Base
    
    # Establishes a connection to the database that's used by all Active Record objects.
    def self.multimaster_connection( config )
      config = config.symbolize_keys
      raise "You must provide a 'multimaster_adapter' value at your database config file" if config[:multimaster_adapter].blank?

      unless self.respond_to?( "#{config[:multimaster_adapter]}_connection" )
      
        begin
          require 'rubygems'
          gem "activerecord-#{config[:multimaster_adapter]}-adapter"
          require "active_record/connection_adapters/#{config[:multimaster_adapter]}_adapter"
        rescue LoadError
          begin
            require "active_record/connection_adapters/#{config[:multimaster_adapter]}_adapter"
          rescue LoadError
            raise "Please install the #{config[:multimaster_adapter]} adapter: `gem install activerecord-#{config[:multimaster_adapter]}-adapter` (#{$!})"
          end
        end
      
      end

      ActiveRecord::ConnectionAdapters::MultiMasterAdapter.new( config )
    end
    
  end
  
  # Adapter
  module ConnectionAdapters

    class MultiMasterAdapter < AbstractAdapter

      # will try to restore connect with primary master after 10 requests to reserved master
      # TODO: get it from config
      RETRY_AFTER = 10
            
      attr_accessor :multimaster_config
      attr_accessor :active_connection_index
      attr_accessor :retry_count
      
      def initialize( config )
        self.multimaster_config = []
        self.retry_count    = 0
        
        hosts = Array(config[:host])
        hosts.each { |host|
          conf = config.symbolize_keys
          conf[:host] = host
          conf[:adapter] = conf.delete(:multimaster_adapter)
          self.multimaster_config << conf
        }

        active_connection
      end

      def reconnect!
        @active = true
        self.active_connection.reconnect!
      end

      def disconnect!
        @active = false
        self.active_connection.disconnect!
      end

      def reset!
        self.active_connection.reset!
      end

      def method_missing( name, *args, &block )
        self.active_connection.send( name.to_sym, *args, &block )
      end

      def active_connection
        begin
          connect_to_master
        rescue
          connect_to_master
        end
      end

      private
      
      def connect_to_master
        master_config = self.multimaster_config.first
        if self.multimaster_config.size == 1
          @active_connection ||= ActiveRecord::Base.send( "#{master_config[:adapter]}_connection", master_config )
        else
          @active_connection ||= connect_to_any_master
          if self.active_connection_index > 0
            self.retry_count += 1
          end
          if self.retry_count > RETRY_AFTER
            self.retry_count = 0
            begin
              master = ActiveRecord::Base.send( "#{master_config[:adapter]}_connection", master_config )
              if master.reconnect! && master.active?
                @active_connection.disconnect!
                @active_connection, self.active_connection_index = master, 0
              end
            rescue
            end
          end
        end
        @active_connection
      end
      
      def connect_to_any_master
        any_connection = nil
        self.multimaster_config.each_with_index  do |config, index|
          begin
            if any_connection = ActiveRecord::Base.send( "#{config[:adapter]}_connection", config )
              self.active_connection_index = index
              break
            end
          end
        end
        any_connection
      end
      
    end

  end

end

# Define the MultiMaster proxy methods
(
  ActiveRecord::ConnectionAdapters::AbstractAdapter.instance_methods(false) +
  ActiveRecord::ConnectionAdapters::Quoting.instance_methods +
  ActiveRecord::ConnectionAdapters::DatabaseStatements.instance_methods +
  ActiveRecord::ConnectionAdapters::SchemaStatements.instance_methods -
  ActiveRecord::ConnectionAdapters::MultiMasterAdapter.instance_methods(false)
).uniq.each do |method|

  ActiveRecord::ConnectionAdapters::MultiMasterAdapter.class_eval %Q!

    def #{method.to_sym}( *args, &block )
        self.active_connection.#{method.to_sym}( *args, &block )
    end

  !

end