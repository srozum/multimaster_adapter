require 'rubygems'
gem 'activerecord', '<= 2.0.0'
require 'active_record'
require 'spec'


$LOAD_PATH << File.expand_path(File.join( File.dirname( __FILE__ ), '..', 'lib' ))

require 'multimaster_adapter'

ActiveRecord::Base.instance_eval do

  def test_connection( config )
    case config[:host]
      when 'primary'
        _primary_master
      when 'secondary'
        _secondary_master
      else
        nil
    end
  end

  def _primary_master=( new_primary_master )
    @_primary_master = new_primary_master
  end

  def _primary_master
    @_primary_master
  end

  def _secondary_master=( new_secondary_master )
    @_secondary_master = new_secondary_master
  end

  def _secondary_master
    @_secondary_master
  end

end

describe ActiveRecord::ConnectionAdapters::MultiMasterAdapter do

  before do

    @mocked_methods = { :verify! => true, :reconnect! => true, :disconnect! => true, :active? => true }

    ActiveRecord::Base._primary_master = mock( 'Primary master connection', @mocked_methods  )
    ActiveRecord::Base._secondary_master = mock( 'Secondary master connection', @mocked_methods )

    @primary_connection = ActiveRecord::Base._primary_master
    @secondary_connection = ActiveRecord::Base._secondary_master
    
    [ @primary_connection, @secondary_connection ].each { |conn|
      conn.stub!( :select_value ).with( "SELECT 1", "test select" ).and_return( true )
    }
    
  end

  after do
    ActiveRecord::Base.clear_active_connections!
  end

  describe 'with single host configuration' do

    before do
      
      @database_setup = {
        :adapter => 'multimaster',
        :username => 'root',
        :database => 'test',
        :host => 'primary',
        :multimaster_adapter => 'test'
      }
      
      ActiveRecord::Base.establish_connection( @database_setup )
      
    end

    it 'Should be a multimaster connection' do
      ActiveRecord::Base.connection.class.should == ActiveRecord::ConnectionAdapters::MultiMasterAdapter
    end

    ActiveRecord::ConnectionAdapters::SchemaStatements.instance_methods.map(&:to_sym).each do |method|
    
      it "Should send the method '#{method}' from ActiveRecord::ConnectionAdapters::SchemaStatements to the master"  do
        @primary_connection.should_receive( method ).and_return( true )
        ActiveRecord::Base.connection.send( method )
      end
    
    end
    
    ActiveRecord::ConnectionAdapters::DatabaseStatements.instance_methods.map(&:to_sym).each do |method|
    
      it "Should send the method '#{method}' from ActiveRecord::ConnectionAdapters::DatabaseStatements to the master"  do
        @primary_connection.should_receive( method ).with('testing').and_return( true )
        ActiveRecord::Base.connection.send( method, 'testing' )
      end
    
    end
        
    it 'Should have a master connection' do
      ActiveRecord::Base.connection.active_connection.should == @primary_connection
    end

    it 'should load the master connection before any method call' do
      ActiveRecord::Base.connection.instance_variable_get(:@active_connection).should == @primary_connection
    end

  end


  describe 'with multi host configuration' do
  
    before do
        
      @database_setup = {
        :adapter => 'multimaster',
        :username => 'root',
        :database => 'test',
        :host => ['primary', 'secondary'],
        :multimaster_adapter => 'test'
      }
    
      ActiveRecord::Base.establish_connection( @database_setup )
    
    end

    it 'Should be a multimaster connection' do
      ActiveRecord::Base.connection.class.should == ActiveRecord::ConnectionAdapters::MultiMasterAdapter
    end
    
    ActiveRecord::ConnectionAdapters::SchemaStatements.instance_methods.map(&:to_sym).each do |method|
    
      it "Should send the method '#{method}' from ActiveRecord::ConnectionAdapters::SchemaStatements to the master"  do
        @primary_connection.should_receive( method ).and_return( true )
        ActiveRecord::Base.connection.send( method )
      end
    
    end
    
    ActiveRecord::ConnectionAdapters::DatabaseStatements.instance_methods.map(&:to_sym).each do |method|
    
      it "Should send the method '#{method}' from ActiveRecord::ConnectionAdapters::DatabaseStatements to the master"  do
        @primary_connection.should_receive( method ).with('testing').and_return( true )
        ActiveRecord::Base.connection.send( method, 'testing' )
      end
    
    end
    
    it 'Should have a master connection' do
      ActiveRecord::Base.connection.active_connection.should == @primary_connection
    end
    
    it 'should load the master connection before any method call' do
      ActiveRecord::Base.connection.instance_variable_get(:@active_connection).should == @primary_connection
    end
  
    it 'should indicate index of master connection' do
      ActiveRecord::Base.connection.instance_variable_get(:@active_connection_index).should == 0
    end
  
  end

  describe 'with multi host configuration and primary down' do
  
    before do
        
      @database_setup = {
        :adapter => 'multimaster',
        :username => 'root',
        :database => 'test',
        :host => ['down', 'secondary'],
        :multimaster_adapter => 'test'
      }
    
      ActiveRecord::Base.establish_connection( @database_setup )
    
    end

    it 'Should be a multimaster connection' do
      ActiveRecord::Base.connection.class.should == ActiveRecord::ConnectionAdapters::MultiMasterAdapter
    end
    
    ActiveRecord::ConnectionAdapters::SchemaStatements.instance_methods.map(&:to_sym).each do |method|
    
      it "Should send the method '#{method}' from ActiveRecord::ConnectionAdapters::SchemaStatements to the secondary master"  do
        @secondary_connection.should_receive( method ).and_return( true )
        ActiveRecord::Base.connection.send( method )
      end
    
    end
    
    ActiveRecord::ConnectionAdapters::DatabaseStatements.instance_methods.map(&:to_sym).each do |method|
    
      it "Should send the method '#{method}' from ActiveRecord::ConnectionAdapters::DatabaseStatements to the secondary master"  do
        @secondary_connection.should_receive( method ).with('testing').and_return( true )
        ActiveRecord::Base.connection.send( method, 'testing' )
      end
    
    end
    
    it 'Should have a secondary master connection' do
      ActiveRecord::Base.connection.active_connection.should == @secondary_connection
    end
    
    it 'should load the secondary master connection before any method call' do
      ActiveRecord::Base.connection.instance_variable_get(:@active_connection).should == @secondary_connection
    end
  
    it 'should indicate index of secondary master connection' do
      ActiveRecord::Base.connection.instance_variable_get(:@active_connection_index).should == 1
    end
  
  end
 
end