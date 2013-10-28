Description
===========

This cookbook exists to automatically make a RAID array using all the Ephemeral block devices (aka "disks", but we cannot know for sure what they are) it can find present to the system it runs on.

The cookbook's default RAID level is 0 - maximum performance with absolutely no redundancy. You must change the attribute to something else if you are worried about dataloss.

The Ephemeral block devices typically have higher performance than other volumes and due to their Ephemeral nature are ideal for high-IO throw-away work or clustered loads that run with sufficient levels of distributed data redundancy: i.e. multi-AZ or multi-region data replication.

These block devices are also typically included with the instance you choose - at no extra cost.

Cloud providers may be sneaky however, since only one of these block devices are available by default when you launch an instance without requisite block device mappings.

See the Usage section for further info on how to get the drives to show up in one example.

This cookbook does not create filesystems, but there is a cookbook out there that does just that : the filesystem cookbook.

Use Case
========

For EC2: See http://aws.amazon.com/ec2/instance-types/ for an up to date list of how many ephemeral block devices/disks there are for each instance type - these devices/disks are otherwise referred to as 'Instance Storage'.

This recipe is only really worth using if there is more than one block device available. At the time of writing the instances that this cookbook suits being run upon are:

* `m1.large` 2 x 420 HDD
* `m1.xlarge` 4 x 420 HDD
* `c1.xlarge` 4 x 420 HDD
* `cc2.8xlarge` 4 x 840 HDD
* `m2.4xlarge` 2 x 840 HDD
* `cr1.8xlarge` 2 x 120 SSD
* `hi1.4xlarge` 2 x 1,024 SSD
* `hs1.8xlarge` 24 x 2,048 HDD
* `cg1.4xlarge` 2 x 840 HDD

Default Behaviour
=================

By default this cookbook grabs all the ephemeral block devices it finds, cleans them up and then creates a raid level 0 array out of them with mdraid.

Suggested Use Pattern
=====================

This cookbook should be used with the [filesystem] cookbook. 

Requirements
============

* A relatively recent common Linux distribution. This recipe is linux-only.

* A cloud provider that Ohai recognises.

* Two or more mapped Ephemeral block devices.

* `mdadm` - This is needed for forming the raid device. We use it via the chef provider.

Recipes
=======

* `default.rb` : A dummy recipe pointing to install.rb
* `install.rb` : Installs everything by calling the rest of the recipes in the right order i.e. once packages have been installed.
* `cleanup.rb` : Unmounts devices and clears partition tables.
* `makeraid.rb` : Creates the raid device, using the mdadm provider.

Attributes
==========

See the contents of `attributes/default.rb` where there are accurate comments and self-explanatory attribute names.

Usage
=====

When you run your instances or create your autoscaling configuration, in the following case for EC2 `m1.xlarge` instances, you must specify the four free emphemeral devices like so:

`--block-device-mapping "/dev/xvdb=ephemeral0,/dev/xvdc=ephemeral1,/dev/xvdd=ephemeral2,/dev/xvde=ephemeral3"`

While we recommend you retain most of the default behaviour, your needs may differ so consider the following example, which includes filesystem creation:

`run_list` ephemeral_raid, filesystem

````JSON
{
  "ephemeral": {
    "raid": {
      "level": "10",
    }
  },
  "filesystems": { 
    "raidfs": {
      "device": "/dev/md0",
      "mount": "/mnt",
      "fstype": "xfs",
      "optons": "noatime,nobarrier",
      "mkfs_options": "-d sunit=128,swidth=2048"
    }
  }
}
````

Development
===========

See the [Github page][https://github.com/mdsol/ephemeral_raid_cookbook]

Authors
=======

* Author: Alex Trull <atrull@mdsol.com> with plenty of ideas bouncing around with Benton Roberts <broberts@mdsol.com>

Special Thanks
==============

* This cookbook was built on the shoulders of giants such as Mike Heffner <mike@librato.com> who originated the original recipe provided significant suggestions for improvement.
* The ephemeral devices helper was taken from Apache 2.0 licensed work by RightScale. Their quality is awesome.

Copyright: 2013–2013 Medidata Solutions, Inc.
