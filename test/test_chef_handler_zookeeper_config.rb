require 'helper'
require 'chef/exceptions'

class ZookeeperConfig
  include Chef::Handler::ZookeeperHandler::Config
end

describe Chef::Handler::ZookeeperHandler::Config do
  before do
    @config_params = {
      :server => '127.0.0.1:2181',
      :znode => '/chef/1.2.3.4',
    }
    @zookeeper_config = ZookeeperConfig.new
  end

  it 'should read the configuration options on config initialization' do
    @zookeeper_config.config_init(@config_params)

    assert_equal @zookeeper_config.server, @config_params[:server]
    assert_equal @zookeeper_config.znode, @config_params[:znode]
  end

  it 'should be able to change configuration options using method calls' do
    @zookeeper_config.server(@config_params[:server])
    @zookeeper_config.znode(@config_params[:znode])

    assert_equal @zookeeper_config.server, @config_params[:server]
    assert_equal @zookeeper_config.znode, @config_params[:znode]
  end

  [ :server, :znode ].each do |required|
    it "should throw an exception when '#{required}' required field is not set" do
      @config_params.delete(required)
      @config_params.each { |key, value| @zookeeper_config.send(key, value) }

      assert_raises(Chef::Exceptions::ValidationFailed) { @zookeeper_config.config_check }
    end
  end

  [ :server, :znode, :start_template, :end_template ].each do |option|

    it "should accept string values in '#{option}' option" do
      @zookeeper_config.send(option, 'test')
    end

    [ true, false, 25, Object.new ].each do |bad_value|
      it "should throw and exception wen '#{option}' option is set to #{bad_value.to_s}" do
        assert_raises(Chef::Exceptions::ValidationFailed) { @zookeeper_config.send(option, bad_value) }
      end
    end
  end

  [ :start_template, :end_template ].each do |template|
    it "should throw an exception when the #{template} file does not exist" do
      @zookeeper_config.send(template, '/tmp/nonexistent-template.erb')
      ::File.stubs(:exists?).with(@zookeeper_config.send(template)).returns(false)

      assert_raises(Chef::Exceptions::ValidationFailed) { @zookeeper_config.config_check }
    end
  end

  describe 'config_init' do

    it 'should accept valid config options' do
      option = :server
      Chef::Log.expects(:warn).never

      @zookeeper_config.config_init({ option => 'valid' })
    end

    it 'should not accept invalid config options' do
      option = :invalid_option
      assert !@zookeeper_config.respond_to?(option)
      Chef::Log.expects(:warn).once

      @zookeeper_config.config_init({ option => 'none' })
    end

    it 'should not accept config options starting by "config_"' do
      option = :config_check
      assert @zookeeper_config.respond_to?(option)
      Chef::Log.expects(:warn).once

      @zookeeper_config.config_init({ option => 'exists but not configurable' })
    end

  end

end
