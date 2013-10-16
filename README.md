Description
===========

This cookbook exists to automatically make and mount raid arrays using all the Ephemeral EC2 disks it can find present to the system it runs on.

These disks typically have higher performance than EBS volumes and due to their Ephemeral nature are ideal for high-IO throw-away work or clustered loads that run with sufficient levels of distributed data redundancy: i.e. multi-AZ or multi-region data replication.

These disks also happen to be included with the instance you choose - at no extra cost.

Amazon are sneaky however, since only one of these disks are mountable by default when you launch an instance without requisite device mappings.

See the Usage section for further info on how to get the drives to show up.

Use Case
========

See http://aws.amazon.com/ec2/instance-types/ for an up to date list of how many Ephemeral disks there are for each instance type - these disks are otherwise referred to as 'Instance Storage'.

This recipe is only really worth using if there is more than one disk available. At the time of writing the instances that this cookbook suits being run upon are:

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

By default this cookbook grabs all the disks it finds, makes a raid 0 array out of them, formats it with `xfs` and remounts it at `/mnt`.

We consider this sensible behaviour given the type of workload this cookbook is aimed at and the nature of the disks.

Requirements
============

* A relatively recent common Linux distribution. This recipe is linux-only.

#### packages

* `${fstype}progs` - We need mkfs.$fstype if we are going to use whatever $fstype you choose.
* `mdadm` - This is needed for forming the raid device.

Recipes
=======

* `default.rb` : A dummy recipe pointing to install.rb
* `install.rb` : Installs everything by calling the rest of the recipes in the right order i.e. once packages have been installed.
* `ephraid.rb` : Clears out the available disks, creates the raid device with them, updates the fstab, creats the mountpoint and mounts the new device at that mountpoint.

Attributes
==========

See the contents of `attributes/default.rb` where there are accurate comments and self-explanatory attribute names.

Usage
=====

Just include `ec2-ephraid` in your role's `run_list`.

And then, when you run your instances or create your autoscaling configuration, in the following case for `m1.xlarge` instances, you must specify the four free emphemeral disks like so:

`--block-device-mapping "/dev/xvdb=ephemeral0","/dev/xvdc=ephemeral1","/dev/xvdd=ephemeral2","/dev/xvde=ephemeral3"`

While we recommend you retain most of the default behaviour, your needs may differ so consider the following example:

```JSON
{
  "ec2": {
    "ephraid": {
      "mountpoint": "/dolphindata"
      "fstype": "ext4"
      "level": "1"
      "owner": "johnnymemnonic"
    }
  }
}
```

Development
===========

See the [Github page][https://github.com/mdsol/ec2_ephraid_cookbook]

Authors
=======

* Author: Alex Trull <atrull@mdsol.com> with plenty of ideas bouncing around with Benton Roberts <broberts@mdsol.com>

Special Thanks
==============

* This was built on the shoulds of giants such as Mike Heffner <mike@librato.com> who originated the original recipe provided significant suggestions for improvement.

Copyright: 2013–2013 Medidata Solutions, Inc.
