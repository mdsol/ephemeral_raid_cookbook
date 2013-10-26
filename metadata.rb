name             'ephemeral_raid'
maintainer       'Medidata Solutions, Inc.'
maintainer_email 'cookbooks@mdsol.com'
license          'Apache 2.0'
description      'Creates Dynamic Ephemeral Raids on EC2'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.0.5'

%w{ ubuntu debian redhat fedora centos scientific amazon }.each do |os|
  supports os
end
