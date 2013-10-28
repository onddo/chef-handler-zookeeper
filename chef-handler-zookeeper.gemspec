$:.push File.expand_path("../lib", __FILE__)
require "chef/handler/zookeeper/version"
chef_version = ENV.key?('CHEF_VERSION') ? "#{ENV['CHEF_VERSION']}" : ['>= 0.9.0']

Gem::Specification.new do |s|
  s.name = 'chef-handler-zookeeper'
  s.version = ::Chef::Handler::ZookeeperHandler::VERSION
  s.date = '2013-10-28'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Send Chef reports to Zookeeper'
  s.description = 'Chef report handler to send notifications to Zookeeper about Chef runs.'
  s.authors = ['Onddo Labs, SL.']
  s.email = 'team@onddo.com'
  s.homepage = 'http://github.com/onddo/chef-handler-zookeeper'
  s.require_path = 'lib'
  s.files = %w(LICENSE README.md) + Dir.glob('lib/**/*')
  s.test_files = Dir.glob('{test,spec,features}/*')

  s.add_dependency 'zk', '~> 1.9'
  s.add_dependency 'erubis'

  s.add_development_dependency 'chef', chef_version
  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'coveralls'
end
