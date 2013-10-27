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

require 'chef/mixin/params_validate'
require 'chef/exceptions'

class Chef
  class Handler
    class ZookeeperHandler < ::Chef::Handler
      module Config
        Config.extend Config # let Config use the methods it contains as instance methods
        include ::Chef::Mixin::ParamsValidate

        REQUIRED = [ 'server', 'znode' ]
      
        def config_init(config={})
          config.each do |key, value|
            if Config.respond_to?(key) and not /^config_/ =~ key.to_s
              self.send(key, value)
            else
              Chef::Log.warn("#{self.class.to_s}: configuration method not found: #{key}.")
            end
          end
        end
      
        def config_check
          REQUIRED.each do |key|
            if self.send(key).nil?
              raise Exceptions::ValidationFailed,
                "Required argument #{key.to_s} is missing!"
            end
          end
      
          [ start_template, end_template ].each do |template|
            if template and not ::File.exists?(template)
              raise Exceptions::ValidationFailed,
                "Template file not found: #{template}."
            end
          end
        end
      
        def server(arg=nil)
          set_or_return(
            :server,
            arg,
            :kind_of => String
          )
        end
      
        def znode(arg=nil)
          set_or_return(
            :znode,
            arg,
            :kind_of => String
          )
        end
      
        def start_template(arg=nil)
          set_or_return(
            :start_template,
            arg,
            :kind_of => String
          )
        end
      
        def end_template(arg=nil)
          set_or_return(
            :end_template,
            arg,
            :kind_of => String
          )
        end
      
      end
    end 
  end 
end 
