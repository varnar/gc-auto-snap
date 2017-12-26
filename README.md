# gc-auto-snap
Shell script for snapshot a disk based on configuration

Calling script in floowing way:

./disk-backup.sh config.cfg

config.cfg file is the configuration file where you defining a instance disks that need to be backup.

Example:

#Configuration format:

#
#[instance name]:[disk name]:[retention days or empty, which will pickup a default from vars.sh][,[disk name]:[retention days or empty, which will pickup a default from vars.sh]]
#

#

#Instance1 - all disk, with retention day 3
instance1:*:3

#Instance2 - disks 1 and 2, with retention day 3 for disk1 and 5 for disk2
instance2:instance2-disk1:3,instance2-disk2:5
