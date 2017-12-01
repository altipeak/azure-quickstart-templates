#!/bin/bash

service rabbitmq-server stop
rm -r /var/lib/rabbitmq/mnesia/*

#configuring os disk
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/sda
n # new partition for logs
p # extended partition
2 # partition number 
  # default start sector
+10G
n # new partition for tmp
p # primary partition
3 # partition number 
  # default start sector
  # default max size
p
w # write the partition table
q # and we're done
EOF

#configuring data disk
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/sdc
n # new partition for backup
p # extended partition
1 # partition number 
  # default start sector
+50G
n # new partition for data
p # extended partition
2 # partion number
  # default start sector
  # default max size
p
w # write the partition table
q # and we're done
EOF

partprobe
mkfs.ext4 /dev/sda2 #logs
mkfs.ext4 /dev/sda3 #tmp

mkfs.ext4 /dev/sdc1 #backup
mkfs.ext4 /dev/sdc2 #data

#configuring tmp
blkid | grep /dev/sda3
UUID=$(blkid | grep /dev/sda3 | grep -Eo 'UUID=\"[^"]*\"')
echo "${UUID//\"} /tmp ext4 errors=remount-ro 0 1" >> /etc/fstab
mount -a

#Migrate postgres data to sdc2
service postgresql stop
mkdir /tmp/pg_main
mv /var/lib/postgresql/9.4/* /tmp/pg_main/.
blkid | grep /dev/sdc2
UUID=$(blkid | grep /dev/sdc2 | grep -Eo 'UUID=\"[^"]*\"')
echo "${UUID//\"} /var/lib/postgresql/9.4 ext4 errors=remount-ro 0 1" >> /etc/fstab
mount -a
mv /tmp/pg_main/* /var/lib/postgresql/9.4/.
chown postgres:postgres /var/lib/postgresql/9.4
#chmod 0700 /var/lib/postgresql/9.4
service postgresql start

#migrate backups to sdc1
mkdir /tmp/patches                              
mv /home/safewalk/patches/* /tmp/patches/.          
blkid | grep /dev/sdc1                                    
UUID=$(blkid | grep /dev/sdc1 | grep -Eo 'UUID=\"[^"]*\"')                               
echo "${UUID//\"} /home/safewalk/patches ext4 errors=remount-ro 0 1" >> /etc/fstab
mount -a                                        
mv /tmp/patches/* /home/safewalk/patches/.    
chown safewalk:safewalk /home/safewalk/patches


#migrate logs to sda2
mkdir /tmp/log
mv /var/log/* /tmp/log/.
blkid | grep /dev/sda2
UUID=$(blkid | grep /dev/sda2 | grep -Eo 'UUID=\"[^"]*\"')
echo "${UUID//\"} /var/log ext4 errors=remount-ro 0 1" >> /etc/fstab
mount -a
mv /tmp/log/* /var/log/.


service rabbitmq-server start
