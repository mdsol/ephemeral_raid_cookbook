# Since these are ephemeral devices there is perhaps no point in other types of raid, but we go ahead and offer.
default[:ephemeral][:raid][:level] = 0
default[:ephemeral][:raid][:spares] = 0
default[:ephemeral][:raid][:chunk_size] = 256
default[:ephemeral][:raid][:read_ahead] = 512
default[:ephemeral][:raid][:device] = "/dev/md0"
default[:ephemeral][:raid][:creation_attempts] = 3
default[:ephemeral][:raid][:force] = false
