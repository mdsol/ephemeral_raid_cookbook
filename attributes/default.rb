# Since these are ephemeral devices there is perhaps no point in other kinds of raid, but the level remains selectable.
default[:ephemeral][:raid][:level] = 0
default[:ephemeral][:raid][:spares] = 0
default[:ephemeral][:raid][:chunk_size] = 256
# A good default for cloud ephemeral disks.
default[:ephemeral][:raid][:read_ahead] = 512
default[:ephemeral][:raid][:device] = "/dev/md0"
# We default to an internal bitmap, but you could force a path to a bitmap at the override attribute level.
if node[:ephemeral][:raid][:level] > 0
  default[:ephemeral][:raid][:bitmap] = "internal"
end
