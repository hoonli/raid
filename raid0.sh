#!/bin/bash

#get disk name count
disks=`lsblk | grep -v NAME | grep -v part | awk '{print $1}' | grep -v a | grep -v -`
disks_count=`lsblk | grep -v NAME | grep -v part | awk '{print $1}' | grep -v a | grep -v - | wc -l`

mount_dir=/data # raid0 mount dir

p_name=mdadm

#updata core
yum clean all
yum update -y


# install mdadm cmd
pkg=$(rpm -qa | grep $p_name)
if [ $? -eq 0 ]
then
    echo "$p_name Already installed"
else
    yum install $p_name -y
    if test $? -eq 0
    then
        echo "$p_name install success"
    else
        echo "$p_name install faild"
    fi
fi


#batch partition
for disk in ${disks[*]}
do
    echo "$disk partition start"
    fdisk $disk << EOF
n
p
1


w
EOF
    echo "partition success"
done

#create Raid linear
disk_str=""
for disk in ${disks[*]}
do
    disk_str=$disk_str" "/dev/$disk
done

mdadm -C -v /dev/md0 -l linear -n $disks_count $disk_str<< EOF
y

EOF

#format
mkfs -t xfs /dev/md0

#Create a mount directory and mount
mkdir -p $mount_dir
mount /dev/md0 $mount_dir

#Modify fstab file
echo "/dev/md0 $mount_dir  xfs  defaults 0 0" >> /etc/fstab

mdadm -Dsv >/etc/mdadm.conf
