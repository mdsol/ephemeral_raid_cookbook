# Since the raid disks are ephemeral there is no point in other types of raid.
default[:ec2][:ephraid][:level] = 0
default[:ec2][:ephraid][:fstype] = "xfs"
default[:ec2][:ephraid][:chunk_size] = 256
default[:ec2][:ephraid][:read_ahead] = 512
default[:ec2][:ephraid][:options] = "defaults,nobootwait,noatime"
default[:ec2][:ephraid][:device] = "/dev/md0"
default[:ec2][:ephraid][:owner] = "root"
default[:ec2][:ephraid][:group] = "root"
default[:ec2][:ephraid][:mode] = "775"
default[:ec2][:ephraid][:mount_point] = "/mnt"
