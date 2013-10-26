#
# Author:: Alex Trull (<atrull@mdsol.com>)
# Cookbook Name:: ephemeral_raid
# Recipe:: raid
#
# Copyright 2013, Medidata Worldwide
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
# Notes:
#
# This recipe based directly on that by Mike Heffner of Librato:
# https://github.com/librato/basenode-chef-kitchen/blob/master/cookbooks/ephemeral/recipes/raid_ephemeral.rb
# 
# Which was in turn modeled after the following :
# https://github.com/riptano/CassandraClusterAMI/blob/master/.startcassandra.py
#

# Obtain the available ephemeral devices. See "libraries/helper.rb" for the definition of
# "get_ephemeral_devices" method.
ephemeral_devices = EphemeralDevices::Helper.get_ephemeral_devices(node.cloud.provider, node)

# We call the mdadm resource provider.
mdadm "#{node[:ephemeral][:raid][:device]}" do
  devices ephemeral_devices
  level node[:ephemeral][:raid][:level]
  chunk node[:ephemeral][:raid][:chunk_size] if node[:ephemeral][:raid][:chunk_size]
  bitmap node[:ephemeral][:raid][:bitmap] if node[:ephemeral][:raid][:bitmap]
  #spares node[:ephemeral][:raid][:spares] # not currently supported by the provider. Wai Opscode Wai ?
  action :create
  notifies :run, "execute[set_readahead_on_device_after_creation]", :immediately
  only_if "which mdadm"
end

# We set the read ahead on the device, but only after the device is created.
execute "set_readahead_on_device_after_creation" do
  command "blockdev --setra #{node[:ephemeral][:raid][:read_ahead]} #{node[:ephemeral][:raid][:device]}"
  action :nothing
  only_if "which blockdev"
  only_if "test -b #{node[:ephemeral][:raid][:device]}"
end

