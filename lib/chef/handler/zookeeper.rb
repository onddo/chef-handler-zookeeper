#
# Author:: Xabier de Zuazo (<xabier@onddo.com>)
# Copyright:: Copyright (c) 2013 Onddo Labs, SL.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/handler'
require 'chef/handler/zookeeper/config'
require 'zk'
require 'erubis'

class Chef
  class Handler
    class ZookeeperHandler < ::Chef::Handler
      include ::Chef::Handler::ZookeeperHandler::Config

      def initialize(config={})
        Chef::Log.debug("#{self.class.to_s} initialized.")
        config_init(config)
      end

      def report
        if !run_status.kind_of?(Chef::RunStatus) or elapsed_time.nil?
          zk.set(znode, start_template_body)
        else
          zk.set(znode, end_template_body)
        end
      end

      protected

      def zk
        @zk ||= begin
          ZK.logger = Chef::Log
          ZK.new(server)
        end
      end

      def start_template_body
        znode_body(start_template || "#{File.dirname(__FILE__)}/zookeeper/templates/start.json.erb")
      end

      def end_template_body
        znode_body(end_template || "#{File.dirname(__FILE__)}/zookeeper/templates/end.json.erb")
      end

      def znode_body(body_template)
        config_check
        template = IO.read(body_template)
        context = self
        eruby = Erubis::Eruby.new(template)
        eruby.evaluate(context)
      end

    end
  end
end
