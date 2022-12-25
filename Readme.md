### Description
Playbook to install postgres, nginx and Django on ec2 Debian instance 

### Prerequisites
* install ansible and git
* Change locale to en_us.UTF-8 `sudo dpkg-reconfigure locales`
* reboot 
* Note: the Debian ec2 had postgres installed and running
```
shell> cat /etc/os-release 
PRETTY_NAME="Debian GNU/Linux 11 (bullseye)"
NAME="Debian GNU/Linux"
VERSION_ID="11"
VERSION="11 (bullseye)"
...
```

### Ansible notes
**Version**
```
ansible-playbook --version
ansible-playbook 2.10.8
  config file = None
  configured module search path = ['/home/admin/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /usr/lib/python3/dist-packages/ansible
  executable location = /usr/bin/ansible-playbook
  python version = 3.9.2 (default, Feb 28 2021, 17:03:44) [GCC 10.2.1 20210110]
```

**Basic Commands**
```
ansible-galaxy collection install community.postgresql
```

For the first time 'check' and then 'play' the tags singularly, in order.
```
ansible-playbook --check --tags prep-work --flush-cache -i inventory.ini playbook.yaml
ansible-playbook --check --tags postgres-work --flush-cache -i inventory.ini playbook.yaml
ansible-playbook --check --tags gunicorn-setup --flush-cache -i inventory.ini playbook.yaml
```

Lastly, then one can run this:
```
ansible-playbook --check --flush-cache -i inventory.ini playbook.yaml
```

### References
* https://www.digitalocean.com/community/tutorials/how-to-set-up-django-with-postgres-nginx-and-gunicorn-on-debian-10
