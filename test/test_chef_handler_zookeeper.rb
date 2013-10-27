require 'helper'
require 'chef/node'
require 'chef/run_status'

class ZK::Client::Fake
  attr_reader :zk_client_new, :server, :znode

  def initialize(host, opts={}, &b)
  end

  def set(path, data, opts={})
    return true
  end

  def fake_new
    @zk_client_new = true
    return self
  end

end

class Chef::Handler::FakeZookeeperHandler < Chef::Handler::ZookeeperHandler

  def get_zookeeper_start_template_body
    start_template_body
  end

  def get_zookeeper_end_template_body
    end_template_body
  end

end

def run_status_new
  @run_status = if Gem.loaded_specs['chef'].version > Gem::Version.new('0.12.0')
    Chef::RunStatus.new(@node, {})
  else
    Chef::RunStatus.new(@node)
  end
end

describe Chef::Handler::ZookeeperHandler do
  before do
    @config = {
      :server => '127.0.0.1:2181',
      :znode => '/chef/1.2.3.4',
    }

    zk = ZK::Client::Threaded.new(@config[:server], { :connect => false })
    ZK::Client::Threaded.stubs(:new).returns(zk) # return a no connecting instance
    ZK::Client::Threaded.any_instance.stubs(:set).returns(true)

    @node = Chef::Node.new
    @node.name('test')
    Chef::Handler::ZookeeperHandler.any_instance.stubs(:node).returns(@node)

    @run_status = run_status_new
    @run_status.start_clock
    @run_status.stop_clock
  end

  it 'should read the configuration options on initialization' do
    @zookeeper_handler = Chef::Handler::ZookeeperHandler.new(@config)
    assert_equal @zookeeper_handler.server, @config[:server]
    assert_equal @zookeeper_handler.znode, @config[:znode]
  end

  it 'should be able to change configuration options using method calls' do
    @zookeeper_handler = Chef::Handler::ZookeeperHandler.new
    @zookeeper_handler.server(@config[:server])
    @zookeeper_handler.znode(@config[:znode])
    assert_equal @zookeeper_handler.server, @config[:server]
    assert_equal @zookeeper_handler.znode, @config[:znode]
  end

  it 'should try to set the znode message at the beginning and end when properly configured' do
    @zookeeper_handler = Chef::Handler::ZookeeperHandler.new(@config)
    ZK::Client::Threaded.any_instance.expects(:set).once

    @zookeeper_handler.run_report_safely(@run_status)
  end

  it 'should create a ZK::Client::Threaded object' do
    @zookeeper_handler = Chef::Handler::ZookeeperHandler.new(@config)
    fake_zookeeper = ZK::Client::Fake.new(@config[:server])
    ZK::Client::Threaded.any_instance.stubs(:new).returns(fake_zookeeper.fake_new)

    @zookeeper_handler.run_report_safely(@run_status)

    assert_equal fake_zookeeper.zk_client_new, true
  end

  describe '#report' do
    before do
      @zookeeper_handler = Chef::Handler::ZookeeperHandler.new(@config)
      @run_status = run_status_new
    end

    describe 'when chef run is not over' do
      before do
        @run_status.start_clock
      end

      it 'should use the start_template when the run is not over' do
        @zookeeper_handler.stubs(:start_template_body).once
        @zookeeper_handler.stubs(:end_template_body).never

        @zookeeper_handler.run_report_unsafe(@run_status)
      end

      it 'should be able to generate the default start_template' do
        @fake_zookeeper_handler = Chef::Handler::FakeZookeeperHandler.new(@config)
        Chef::Handler::FakeZookeeperHandler.any_instance.stubs(:node).returns(@node)
        @fake_zookeeper_handler.run_report_unsafe(@run_status)

        @fake_zookeeper_handler.get_zookeeper_start_template_body.must_match Regexp.new('"start_time":')
      end

      it 'should throw an exception when the start_template file does not exist' do
        @config[:start_template] = '/tmp/nonexistent-template.erb'
        @zookeeper_handler = Chef::Handler::ZookeeperHandler.new(@config)

        assert_raises(Chef::Exceptions::ValidationFailed) { @zookeeper_handler.run_report_unsafe(@run_status) }
      end

      it 'should be able to generate the start_template when configured as an option' do
        body_msg = 'My Template'
        @config[:start_template] = '/tmp/existing-template.erb'
        ::File.stubs(:exists?).with(@config[:start_template]).returns(true)
        IO.stubs(:read).with(@config[:start_template]).returns(body_msg)
        @fake_zookeeper_handler = Chef::Handler::FakeZookeeperHandler.new(@config)
        Chef::Handler::FakeZookeeperHandler.any_instance.stubs(:node).returns(@node)
        @fake_zookeeper_handler.run_report_unsafe(@run_status)

        assert_equal @fake_zookeeper_handler.get_zookeeper_start_template_body, body_msg
      end

    end # describe when chef run is not over

    describe 'when chef run is over' do
      before do
        @run_status.start_clock
        @run_status.stop_clock
      end

      it 'should use the end_template when the run is over' do
        @zookeeper_handler.stubs(:end_template_body).once
        @zookeeper_handler.stubs(:start_template_body).never

        @zookeeper_handler.run_report_unsafe(@run_status)
      end

      it 'should be able to generate the default end_template' do
        @fake_zookeeper_handler = Chef::Handler::FakeZookeeperHandler.new(@config)
        Chef::Handler::FakeZookeeperHandler.any_instance.stubs(:node).returns(@node)
        @fake_zookeeper_handler.run_report_unsafe(@run_status)

        @fake_zookeeper_handler.get_zookeeper_end_template_body.must_match Regexp.new('"end_time":')
      end

      it 'should throw an exception when the end_template file does not exist' do
        @config[:end_template] = '/tmp/nonexistent-template.erb'
        @zookeeper_handler = Chef::Handler::ZookeeperHandler.new(@config)

        assert_raises(Chef::Exceptions::ValidationFailed) { @zookeeper_handler.run_report_unsafe(@run_status) }
      end

      it 'should be able to generate the end_template when configured as an option' do
        body_msg = 'My Template'
        @config[:end_template] = '/tmp/existing-template.erb'
        ::File.stubs(:exists?).with(@config[:end_template]).returns(true)
        IO.stubs(:read).with(@config[:end_template]).returns(body_msg)
        @fake_zookeeper_handler = Chef::Handler::FakeZookeeperHandler.new(@config)
        Chef::Handler::FakeZookeeperHandler.any_instance.stubs(:node).returns(@node)
        @fake_zookeeper_handler.run_report_unsafe(@run_status)

        assert_equal @fake_zookeeper_handler.get_zookeeper_end_template_body, body_msg
      end

    end # describe when chef run is over

    describe 'when called without run_status (chef_handler LWRP)' do
      it 'should use the start_template when the run is not over' do
        @zookeeper_handler.stubs(:start_template_body).once
        @zookeeper_handler.stubs(:end_template_body).never

        @zookeeper_handler.run_report_unsafe(Object.new)
      end
    end

  end # describe #report

end
