#
# Cookbook Name:: ec2-ephraid
# Recipe:: install
#
# Copyright 2013 Medidata Solutions Worldwide
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This recipe/cookbook expects to be run very early in the runlist because other software might install on paths and devices it creates.

# The mdadm package is used to create the array.
package "mdadm" do
  action :install
  ignore_failure true
end

# We try to correctly prefix the tools we will need
if node[:ec2][:ephraid][:fstype] =~ /ext/
  # ext filesystems have tools called eNfsprogs or similar which is really silly but just the way it is - other filesystems are more sensible.
  fsversion = node[:ec2][:ephraid][:fstype].gsub!(/\D/, "") 
  toolprefix = ::File.join("e", fsversion, "fs")
else
  toolprefix = node[:ec2][:ephraid][:fstype]
end

# If we're going with a special $fstype, we probably need some utilities to make it work, so we shall attempt to install them through fuzzy suffixing. The ignore_failure is key here since many of these package name combinations will not exist.
[ "", "progs" , "-progs", "tools", "-tools", "progs-devel" ,"-progs-devel", "dump", "libs", "libs-dev", "-devel", "devel"  ].each do |fuzzysuffix|
  package "#{toolprefix}#{fuzzysuffix}" do
    action :install
    ignore_failure true
    not_if "which mkfs.#{node[:ec2][:ephraid][:fstype]}"
  end
end

# We include the recipe that actually does things if the commands it needs are present and accounted for in the path.
include_recipe "ec2-ephraid::ephraid" do
  only_if "which mdadm"
  only_if "which mkfs.#{node[:ec2][:ephraid][:fstype]}"
end
