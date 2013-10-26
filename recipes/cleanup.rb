#
# Author:: Alex Trull (<atrull@mdsol.com>)
# Cookbook Name:: ephemeral_raid
# Recipe:: cleanup 
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

# Obtain the available ephemeral devices. See "libraries/helper.rb" for the definition of
# "get_ephemeral_devices" method.
ephemeral_devices = EphemeralDevices::Helper.get_ephemeral_devices(node.cloud.provider, node)

# Some cleanup of cloud defaults that would conflict with the results of this recipe
mount "/mnt/ephemeral" do
  device "/dev/xvdb"
  action :umount
end

mount "/mnt/ephemeral" do
  device "/dev/xvdb"
  action :disable
end

mount "/mnt" do
  device "/dev/xvdb"
  action :umount
end

mount "/mnt" do
  device "/dev/xvdb"
  action :disable
end

# We cleanup the devices we found
ruby_block "unmount_and_zero_superblocks_of_ephemeral_devices" do
  block do

    Chef::Log.info("Deformatting devices #{ephemeral_devices.join(",")}")

    ephemeral_devices.each do |dev|
      Chef::Log.info("Unmounting, Removing Partition Table and Zeroing Superblock of device #{dev}")
      system("umount #{dev}")
      system("parted #{dev} -s -- rm 1")
      system("dd if=/dev/zero of=#{dev} bs=5M count=1")
      system("mdadm --zero-superblock #{dev}")
    end

  end
  action :create
  not_if { File.exists?(node[:ephemeral][:raid][:device]) } 
  notifies :create, "mdadm[#{node[:ephemeral][:raid][:device]}]", :immediately
end

