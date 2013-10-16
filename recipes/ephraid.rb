#
# Author:: Alex Trull (<atrull@mdsol.com>)
# Cookbook Name:: ec2-ephraid
# Recipe:: ephraid
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
# This recipe based directly on that by Mike Heffner of Librato:
# https://github.com/librato/basenode-chef-kitchen/blob/master/cookbooks/ec2/recipes/raid_ephemeral.rb
# 
# Which was in turn modeled after the following :
# https://github.com/riptano/CassandraClusterAMI/blob/master/.startcassandra.py

# Remove EC2 default /mnt from fstab, notifying the destructive parts to run.
mount "/mnt" do
  device "/dev/xvdb"
  action :umount
end

# Remove EC2 default /mnt from fstab, notifying the destructive parts to run.
mount "/mnt" do
  device "/dev/xvdb"
  action :disable
end

# We create the directory using the idempotent chef resource
directory node[:ec2][:ephraid][:mount_point] do
  owner node[:ec2][:ephraid][:owner]
  group node[:ec2][:ephraid][:group]
  mode node[:ec2][:ephraid][:mode]
  recursive true
end

# We mount the device using the idempotent chef resource
mount "Mount #{node[:ec2][:ephraid][:device]} to #{node[:ec2][:ephraid][:mount_point]}" do
  device node[:ec2][:ephraid][:device]
  mount_point node[:ec2][:ephraid][:mount_point]
  fstype node[:ec2][:ephraid][:fstype]
  options node[:ec2][:ephraid][:options]
  pass 0
  dump 0
  action [:mount, :enable]
  only_if  { File.exists?(node[:ec2][:ephraid][:device]) }
end

# We cleanup the old drives we found.
ruby_block "format_drives" do
  block do
    devices = %x{ls /dev/sd* /dev/xvd* 2> /dev/null}.split("\n").
      delete_if{|d| ["/dev/sda1", "/dev/xvda1"].include?(d)}

    Chef::Log.info("Formatting drives #{devices.join(",")}")

    # Create one giant Linux partition per drive
    fmtcmd=",,L\n"
    devices.each do |dev|
      system("umount #{dev}")

      # Clear "invalid flag 0x0000 of partition table 4" by issuing a write
      IO.popen("fdisk -c -u #{dev}", "w") do |f|
        f.puts "w\n"
      end

      IO.popen("sfdisk -L --no-reread #{dev}", "w") do |f|
        f.puts fmtcmd
      end
    end
  end
  action :create
  not_if { File.exists?(node[:ec2][:ephraid][:device]) }
  # we are called when the default /mnt is removed above - not before and never after.
  notifies :create, "ruby_block[create_raid]", :immediately
end

# The main block that creates the raid array - even if it just an array of one. 
ruby_block "create_raid" do
  block do
    # Get partitions
    parts = %x{ls /dev/sd*[0-9] /dev/xvd*[0-9] 2> /dev/null}.split("\n").
      delete_if{|d| ["/dev/sda1", "/dev/xvda1"].include?(d)}
    parts = parts.sort

    Chef::Log.info("Partitions to raid: #{parts.join(",")}")

    # Unmount
    parts.each do |part|
      system("umount #{part}")
    end

    # Wait for devices to settle.
    system("sleep 3")

    args = ["--create #{node[:ec2][:ephraid][:device]}",
            "--chunk=#{node[:ec2][:ephraid][:chunk_size]}",
            "--level #{node[:ec2][:ephraid][:level]}"]

    # Smaller nodes only have one RAID device
    if parts.length == 1
      args << '--force'
    end

    args << "--raid-devices #{parts.length}"

    # We try up to 3 times to make this raid array.
    try = 1
    tries = 3
    failed_create = false
    begin
      failed_create = false

      r = system("y| mdadm #{args.join(' ')} #{parts.join(' ')}")
      puts "Failed to create raid with command \"y| mdadm #{args.join(' ')} #{parts.join(' ')}\"" unless r

      # Scan
      File.open("/etc/mdadm/mdadm.conf", "w") do |f|
        f << "DEVICE #{parts.join(' ')}\n"
      end
      system("sleep 5")

      r = system("mdadm --detail --scan >> /etc/mdadm/mdadm.conf")
      puts "Failed to initialize raid device" unless r
      system("sleep 10")

      r = system("blockdev --setra #{node[:ec2][:ephraid][:read_ahead]} #{node[:ec2][:ephraid][:device]}")
      puts "Failed to set read-ahead" unless r
      system("sleep 10")

      r = system("mkfs -t #{node[:ec2][:ephraid][:fstype]} -f #{node[:ec2][:ephraid][:device]}")
      unless r
        puts "Failed to format raid device"
        system("mdadm --stop #{node[:ec2][:ephraid][:device]}")
        system("mdadm --zero-superblock #{parts.first}")

        try += 1
        failed_create = true
      end
    end while failed_create && try <= tries

    exit 0 if failed_create
  end
  action :nothing
  not_if {File.exist?("#{node[:ec2][:ephraid][:device]}")}
  # We only run if there is no device created, and we are only called after the disks are formatted.
  # And after succeeding we create the mount, and mount and enable the fstab entry.
  notifies :create, "directory[#{node[:ec2][:ephraid][:mount_point]}]", :immediately
  notifies :mount, "mount[Mount #{node[:ec2][:ephraid][:device]} to #{node[:ec2][:ephraid][:mount_point]}]", :immediately
  notifies :enable, "mount[Mount #{node[:ec2][:ephraid][:device]} to #{node[:ec2][:ephraid][:mount_point]}]", :immediately
end

