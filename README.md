# gc-auto-snap
Shell script for snapshot a disk based on configuration

Calling script in floowing way:

./disk-backup.sh config.cfg

config.cfg file is the configuration file where you defining a instance disks that need to be backup.

#Configuration format:

[instance name]:[disk name]:[retention days],[disk name]:[retention days]

#Example

#Instance1 - all disk, with retention day 3
instance1:*:3

#Instance2 - disks1 and disk2, with retention day 3 for disk1 and 5 for disk2
instance2:disk1:3,disk2:5
