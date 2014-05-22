#
# Cookbook Name:: ephemeral_raid
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

# This cookbook expects to be run very early in the runlist because other software might install on paths and devices it creates.

if !node.attribute?('cloud') || !node['cloud'].attribute?('provider')

  log "Not running on an OHAI-recognised cloud. Going no further."

else

  # Obtain the available ephemeral devices. See "libraries/helper.rb" for the definition of
  # "get_ephemeral_devices" method.
  ephemeral_devices = EphemeralDevices::Helper.get_ephemeral_devices(node.cloud.provider, node)

  if ephemeral_devices.empty?
   
    # No devices found 

    log "Ephemeral devices not found"

  elsif ( ephemeral_devices.length >= 2 ) || ( ephemeral_devices.length == 1 && node[:ephemeral][:raid][:force] == true )

    # We have more than one, or we have one and we are forcing it.

    log "Ephemeral devices have been found"

    package "mdadm"

    include_recipe "ephemeral_raid::cleanup" do
      only_if "which umount && which parted && which dd && which mdadm && which blockdev"
    end

    include_recipe "ephemeral_raid::makeraid" do
      only_if "which mdadm && which blockdev"
    end

  end

end
