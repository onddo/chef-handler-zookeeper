# Chef Handler Zookeeper

A simple Chef report handler to send notifications to Zookeeper about Chef runs.

This Chef Handler is heavily based on [Chef Handler SNS](https://github.com/onddo/chef-handler-sns) code.

* http://wiki.opscode.com/display/chef/Exception+and+Report+Handlers

[![Gem Version](https://badge.fury.io/rb/chef-handler-zookeeper.png)](http://badge.fury.io/rb/chef-handler-zookeeper)
[![Dependency Status](https://gemnasium.com/onddo/chef-handler-zookeeper.png)](https://gemnasium.com/onddo/chef-handler-zookeeper)
[![Code Climate](https://codeclimate.com/github/onddo/chef-handler-zookeeper.png)](https://codeclimate.com/github/onddo/chef-handler-zookeeper)
[![Build Status](https://travis-ci.org/onddo/chef-handler-zookeeper.png)](https://travis-ci.org/onddo/chef-handler-zookeeper)

## Requirements

* A Zookeeper server.
* Uses the `zk` Ruby gem.

## Usage

You can install this handler in two ways:

### Method 1: In the Chef config file

You can install the RubyGem and configure Chef to use it:

    gem install chef-handler-zookeeper

Then add to the configuration (`/etc/chef/solo.rb` for chef-solo or `/etc/chef/client.rb` for chef-client):

```ruby
require "chef/handler/zookeeper"

# Create the handler
zookeeper_handler = Chef::Handler::ZookeeperHandler.new

# Some Zookeeper configurations
zookeeper_handler.server "zookeeper.mydomain.com"
zookeeper_handler.znode "/chef/#{`hostname`.chomp}/chef_status"

# Add your handler
start_handlers << zookeeper_handler
exception_handlers << zookeeper_handler
report_handlers << zookeeper_handler
```

### Method 2: In a recipe with the chef_handler LWRP

Use the [chef_handler LWRP](http://community.opscode.com/cookbooks/chef_handler), creating a recipe with the following:

```ruby
# A compiler is required for the `zk` gem
node.default['build_essential']['compiletime'] = true
include_recipe 'build-essential'

# Handler configuration options
argument_array = [
  :server => "zookeeper.mydomain.com:2181",
  :znode => "/chef/somepath/chef_status",
]

# Install the `chef-handler-zookeeper` RubyGem during the compile phase
chef_gem "chef-handler-zookeeper"

# Then activate the handler with the `chef_handler` LWRP
chef_handler "Chef::Handler::ZookeeperHandler" do
  source "#{Gem::Specification.find_by_name("chef-handler-zookeeper").lib_dirs_glob}/chef/handler/zookeeper"
  arguments argument_array
  supports :report => true, :exception => true
  action :enable
end
```

If you have an old version of gem package (< 1.8.6) without `find_by_name` or old chef-client (< 0.10.10) without `chef_gem`, you can try creating a recipe similar to the following:

```ruby
# A compiler is required for the `zk` gem
node.default['build_essential']['compiletime'] = true
include_recipe 'build-essential'

# Handler configuration options
argument_array = [
  :server => "zookeeper.mydomain.com:2181",
  :znode => "/chef/somepath/chef_status",
]

# Install the `chef-handler-zookeeper` RubyGem during the compile phase
if defined?(Chef::Resource::ChefGem)
  chef_gem "chef-handler-zookeeper"
else
  gem_package("chef-handler-zookeeper") do
    action :nothing
  end.run_action(:install)
end

# Get the installed `chef-handler-zookeeper` gem path
zookeeper_handler_path = Gem::Specification.respond_to?("find_by_name") ?
  Gem::Specification.find_by_name("chef-handler-zookeeper").lib_dirs_glob :
  Gem.all_load_paths.grep(/chef-handler-zookeeper/).first

# Then activate the handler with the `chef_handler` LWRP
chef_handler "Chef::Handler::ZookeeperHandler" do
  source "#{zookeeper_handler_path}/chef/handler/zookeeper"
  arguments argument_array
  supports :report => true, :exception => true
  action :enable
end
```

#### start_handler

If you want to run also as a *start handler* using `chef_handler` cookbook, you can use a recipe similar to the following:

```ruby
# [...]

# We will need to install the chef handler at compile time
chef_handler "Chef::Handler::ZookeeperHandler" do
# [...]
  action :nothing
end.run_action(:enable)

# based on code from chef-sensu-handler cookbook: https://github.com/needle-cookbooks/chef-sensu-handler/blob/master/recipes/default.rb
ruby_block 'trigger_start_handlers' do
  block do
    require 'chef/run_status'
    require 'chef/handler'

    # a bit tricky, required by the default start.json.erb template to have access to node
    Chef::Handler.run_start_handlers(self)
  end
  action :nothing
end.run_action(:create)
```

## Handler Configuration Options

The following options are available to configure the handler:

* `server` - The Zookeeper server hostname and port (required).
* `znode` - Path of the znode to write to (required). **The znode must already exist**.
* `start_template` - Full path of an erubis template file to use for the znode body on Chef run start (optional).
* `end_template` - Full path of an erubis template file to use for the znode body when Chef run ended (optional).

### start_template and end_template

This configuration options need to contain the full path of an erubis template. For example:

```ruby
# recipe "myapp::zookeeper_handler"

cookbook_file "chef_handler_zookeeper_body.erb" do
  path "/tmp/chef_handler_zookeeper_body.erb"
  # [...]
end

argument_array = [
  :server => "zookeeper.mydomain.com:2181",
  :znode => "/chef/somepath/chef_status",
  :end_template => "/tmp/chef_handler_zookeeper_body.erb",
]
chef_handler "Chef::Handler::ZookeeperHandler" do
  # [...]
  arguments argument_array
end
```

```erb
<%# file "myapp/files/default/chef_handler_zookeeper_body.erb" %>

Node Name: <%= node.name %>
<% if node.attribute?("fqdn") -%>
Hostname: <%= node.fqdn %>
<% end -%>

Chef Run List: <%= node.run_list.to_s %>
Chef Environment: <%= node.chef_environment %>

<% if node.attribute?("ec2") -%>
Instance Id: <%= node.ec2.instance_id %>
Instance Public Hostname: <%= node.ec2.public_hostname %>
Instance Hostname: <%= node.ec2.hostname %>
Instance Public IPv4: <%= node.ec2.public_ipv4 %>
Instance Local IPv4: <%= node.ec2.local_ipv4 %>
<% end -%>

Chef Client Elapsed Time: <%= elapsed_time.to_s %>
Chef Client Start Time: <%= start_time.to_s %>
Chef Client Start Time: <%= end_time.to_s %>

<% if exception -%>
Exception: <%= run_status.formatted_exception %>
Stacktrace:
<%= Array(backtrace).join("\n") %>

<% end -%>
```

The following variables are accessible inside the template:

* `start_time` - The time the chef run started.
* `end_time` - The time the chef run ended.
* `elapsed_time` - The time elapsed between the start and finish of the chef run.
* `run_context` - The Chef::RunContext object used by the chef run.
* `exception` - The uncaught Exception that terminated the chef run, or nil if the run completed successfully.
* `backtrace` - The backtrace captured by the uncaught exception that terminated the chef run, or nil if the run completed successfully.
* `node` - The Chef::Node for this client run.
* `all_resources` - An Array containing all resources in the chef run's resource_collection.
* `updated_resources` - An Array containing all resources that were updated during the chef run.
* `success?` - Was the chef run successful? True if the chef run did not raise an uncaught exception.
* `failed?` - Did the chef run fail? True if the chef run raised an uncaught exception.

Default templates are in the [templates](https://github.com/onddo/chef-handler-zookeeper/tree/master/lib/chef/handler/zookeeper/templates) directory.

**Note:** When using `start_template` with the **chef_handler cookbook**, only the `node` variable will be accesible from the template.

## Running the tests

Minitest tests can be run as usual:

    rake test

# TODO

* Support for znode creation:
  * Including *:create* boolean, *:acl* for the ACL and *:recursive*.
* Add digest authentication support.

## Contributing

[Pull Requests](http://github.com/onddo/chef-handler-zookeeper/pulls) are welcome.

## License and Author

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Author:**          | Xabier de Zuazo (<xabier@onddo.com>)
| **Copyright:**       | Copyright (c) 2013 Onddo Labs, SL. (www.onddo.com)
| **License:**         | Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

