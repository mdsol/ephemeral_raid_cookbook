#
# Author:: Alex Trull (<atrull@mdsol.com>)
# Cookbook Name:: ephemeral-raid
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

# The main block that creates the raid array.
ruby_block "create_array_of_ephemeral_devices" do
  block do

    Chef::Log.info("Devices to raid: #{ephemeral_devices.join(",")}")

    # Wait for devices to settle.
    system("sleep 3")

    # We may be forcing things on nodes with single ephemeral devices.
    if node[:ephemeral][:raid][:force]
      creation_args << '--force'
    end

    # We put together our arguments
    creation_args = ["--create #{node[:ephemeral][:raid][:device]}",
                     "--chunk=#{node[:ephemeral][:raid][:chunk_size]}",
                     "--spare-devices=#{node[:ephemeral][:raid][:spares]}", 
                     "--level=#{node[:ephemeral][:raid][:level]}",
                     "--raid-devices=#{ephemeral_devices.length}"]

    # We try up to N times to create this raid array.
    try = 1
    maximum_creation_retries = node[:ephemeral][:raid][:creation_attempts]
    failed_create = false
    begin
      # Main creation Loop
      failed_create = false

      ## Raid Creation
      puts "Attempting to create raid with command: y| mdadm #{creation_args.join(' ')} #{ephemeral_devices.join(' ')}"
      create_mdraid_array = system("mdadm #{creation_args.join(' ')} #{ephemeral_devices.join(' ')}")
      puts "Failed to create raid with command \"y| mdadm #{creation_args.join(' ')} #{ephemeral_devices.join(' ')}\"" unless create_mdraid_array

      ## Configuration Section
      # Create the list of devices
      puts "Creating mdadm configuration"
      File.open("/etc/mdadm/mdadm.conf", "w") do |f|
        f << "DEVICE #{ephemeral_devices.join(' ')}\n"
      end
      system("sleep 5")
      
      # Scan mdraid's config from the running setup into the config
      puts "Scanning disks to put into mdadm configuration"
      scan_mdraid_settings = system("mdadm --detail --scan >> /etc/mdadm/mdadm.conf")
      puts "Failed to scan raid device" unless scan_mdraid_settings
      system("sleep 10")
     
      ## Readahead setting section - if we can set readahead on the device, we think the creation was a success !
      puts "Setting Readahead"
      set_readahead = system("blockdev --setra #{node[:ephemeral][:raid][:read_ahead]} #{node[:ephemeral][:raid][:device]}")
      unless set_readahead
        puts "Failed to readahead - array creation attempt #{try}/#{maximum_creation_retries} considered a failure"
        system("mdadm --stop #{node[:ephemeral][:raid][:device]}")
        system("mdadm --remove #{node[:ephemeral][:raid][:device]}")
        ephemeral_devices.each do |dev|
          system("mdadm --zero-superblock #{dev}")
        end
        try += 1
        failed_create = true
      end

    end while failed_create && try <= maximum_creation_retries

    exit 1 if failed_create

  end

  action :nothing
  not_if {File.exist?("#{node[:ephemeral][:raid][:device]}")}
  # On our own we do nothing, we only run if there is no device created and we are only called after and if unmount_and_zero_superblocks_of_ephemeral_devices has run.
end

