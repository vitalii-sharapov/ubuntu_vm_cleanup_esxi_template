#Apply any system updates & remove any obsolete packages
sudo apt update && sudo apt upgrade -y
sudo apt clean && sudo apt -y autoremove --purge

#Install packages
sudo apt-get install -y open-vm-tools

#Clear audit logs
if [ -f /var/log/audit/audit.log ]; then
    cat /dev/null > /var/log/audit/audit.log
fi
if [ -f /var/log/wtmp ]; then
    cat /dev/null > /var/log/wtmp
fi
if [ -f /var/log/lastlog ]; then
    cat /dev/null > /var/log/lastlog
fi

#Clear the SSH
sudo rm -f /etc/ssh/ssh_host_*

#Reset the hostname
sudo cat /dev/null > /etc/hostname

#Reset the machine id
sudo echo -n > /etc/machine-id

#Cleanup apt
sudo apt-get clean

#Setup script to generate new ssh keys at boot
cat << 'EOL' | sudo tee /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
test -f /etc/ssh/ssh_host_dsa_key || dpkg-reconfigure openssh-server
exit 0
EOL

#Make sure the script is executable
sudo chmod +x /etc/rc.local

#Disable swap for K8s
sudo swapoff --all
sudo sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

#Prevent ctrl-alt-del from causing a reboot
sudo systemctl mask ctrl-alt-del.target

#Disable LTS Upgrade MOTD
sudo sed -i '16 s/.*Prompt.*/Prompt=never/' /etc/update-manager/release-upgrades

#Remove some of the initial setup packages
sudo apt remove --purge gnome-initial-setup gnome-online-accounts update-manager-core -y

#Disable cloud-init and instead rely on VMware Guest Customisation specs 
sudo cloud-init clean --logs
sudo touch /etc/cloud/cloud-init.disabled
sudo rm -rf /etc/netplan/*.yaml
sudo apt purge cloud-init -y
sudo apt autoremove -y

#Don't clear /tmp
sudo sed -i 's/D \/tmp 1777 root root -/#D \/tmp 1777 root root -/g' /usr/lib/tmpfiles.d/tmp.conf

#Remove cloud-init and rely on dbus for open-vm-tools
sudo sed -i 's/Before=cloud-init-local.service/After=dbus.service/g' /lib/systemd/system/open-vm-tools.service


#Remove cleanup script
sudo rm -rf /home/localadmin/ubuntu_cleanup.sh

#Clear the history & shutdown the VM
sudo history -c
sudo history -w
sudo shutdown -h now
