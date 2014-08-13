xe-unikernel-upload
===================

A simple tool to upload a Unikernel to a XenServer pool.

Simple usage:
```
xe-unikernel-upload --username=root --password=password \
   --uri=https://my.xenserver/ --path=my-unikernel
```
The program will create a VDI, upload a bootable disk image into it
and print the VDI uuid.

xe-unikernel-upload will read the $HOME/.xe config file (if it exists)
and interpret the same keys as the 'xe' cli i.e.
```
server=<DNS or IP>
username=<username>
password=<password>
```
This means you can simply say:
```
xe-unikernel-upload --path=my-unikernel
```

