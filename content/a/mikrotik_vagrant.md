+++
title = "How to create a Vagrant box for Mikrotik CHR"
date = 2021-11-01
draft = false
tags = ["vagrant", "mikrotik", "routeros", "networking", "chr", "libvirt", "kvm", "qemu"]
+++

Some quick instructions to create a Vagrant box (libvirt box) for Mikrotik CHR RouterOS, version 6.

First of all, you need to download the RouterOS CHR vmdk file from the Mikrotik's website, and convert it to qcow2 format with the `qemu-img` tool:

```
qemu-img convert -f vmdk -O qcow2 chr-6.49.1.vmdk chr-6.49.1.qcow2
```

After that, you can use it with `virt-install` to boot up a CHR instance for the first time, and apply some initial configuration:

```
virt-install \
    --connect=qemu:///system \
    --name=chr-6.49.1 \
    --os-type=linux \
    --arch=x86_64 \
    --cpu host \
    --vcpus=1 \
    --hvm \
    --ram=512 \
    --disk path=chr-6.49.1.qcow2,bus=ide,format=qcow2 \
    --network=network:vagrant-libvirt,model=virtio \
    --import --noautoconsole --graphics none
```

You can connect to the KVM instance using `virsh`:

```
virsh console chr-6.49.1
```
accept the license, and verify the IP address taken using DHCP.

You also need to add a `vagrant` user, and copy the Vagrant SSH Public Key. Let's start with the key file copy, using *SCP*:

```
scp ~/.vagrant.d/insecure_private_key admin@192.168.121.50:
```

Using the console, add the user and associate the public key to it:
```
/user add group=full name=vagrant
/user set 1 password=vagrant
/user ssh-keys import public-key-file=insecure_private_key user=vagrant
```

You can also test the result trying to connect with the new user and its key:
```
ssh vagrant@192.168.121.53 -i ~/.vagrant.d/insecure_private_key
```

Now it comes the hacks: it seems that RouterOS saves somewhere the existing network interfaces, together with their own names, checking for their existance on the subsequent boots.
Every time it founds a new ethernet interface, this will be added to the list with a "sequence number", i.e., *ether2*, *ether3*, and so on.

The network interface we are using during the installation won't be present anymore on the next boot time, and the "new" first interface will be called *ether2* - which we don't like it.

But, we can simply rename the current interface to something different than *ether1*. Doing so, the "new" first interface will be called exactly *ether1*. Much better!

At the same time, since any configuration about DHCP Client is linked to the current interface (and the configuration is referenced by ID, not by interface name), we need to change the DHCP Client config on every boot to use the new interface.
This can be done using a *system scheduler script* at every system startup.

```
/interface ethernet set 0 name=temp

/system scheduler
add name="boot" on-event=":delay 00:00:10 \r\n/ip dhcp-client set 0 interface=[/interface ethernet get 0 name]" start-time=startup interval=0s disabled=no
```

Additionally, we do want to enable **IPv6**:

```
/system package enable ipv6
```

After that, you can shutdown the VM.
```
/system shutdown
```

We need then to create the *Vagrant* *metadata* file (*metadata.json*), in the same directory of our qcow file, with the following content:

```
{"provider":"libvirt","format":"qcow2"}
```

and to create the final *box* file we just need to run:
```
curl -O https://raw.githubusercontent.com/vagrant-libvirt/vagrant-libvirt/master/tools/create_box.sh
bash create_box.sh chr-6.49.1.qcow2
```

The *box* file can be imported into *Vagrant* with:
```
vagrant box add chr-6.49.1.box --name mikrotik/chr
```

**NOTE**: this *Vagrant* box image has been created for use with the **netlab** (formerly *netsim-tools*): https://github.com/ipspace/netlab
