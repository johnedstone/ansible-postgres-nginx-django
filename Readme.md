### Description
Playbook to install postgres, nginx and Django on ec2 Debian instance 

### Prerequisites
* install ansible, rsync and git
* Change locale to en_us.UTF-8 `sudo dpkg-reconfigure locales`
* reboot 
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

### Ansible playbooks
For the first time 'check' and then 'play' the tags singularly, in order.
```
ansible-playbook --check --diff --tags prep-work --flush-cache -i inventory.ini playbook.yaml
ansible-playbook --check --diff --tags postgres --flush-cache -i inventory.ini playbook.yaml
ansible-playbook --check --diff --tags letsencrypt --flush-cache -i inventory.ini playbook.yaml
ansible-playbook --check --diff --tags gunicorn-setup --flush-cache -i inventory.ini playbook.yaml
ansible-playbook --check --diff --tags nginx-setup --flush-cache -i inventory.ini playbook.yaml
```

Play the `letsencrypt` tag with the variable `install_lego: true` just the first time,  
```
ansible-playbook --check --tags letsencrypt  --flush-cache -i inventory.ini playbook.yaml
```
then, set `install_lego: false`

Continue on with `use_lets_encrypt: false` ...
```
ansible-playbook --check --tags nginx-setup  --flush-cache -i inventory.ini playbook.yaml
```

After starting nginx with the self-signed certs,  
install certs from Let's Encypt similar to this example:
```
sudo /opt/apps/letsencrypt/lego --path /opt/apps/letsencrypt --http --http.webroot /opt/apps/acme_validation --domains "my-website.com"  --email 'my-email@my_email.com' run --preferred-chain 'ISRG Root X1'
```

And finally, set `use_lets_encrypt: true` and run again ..
```
ansible-playbook --diff --check --tags nginx-setup  --flush-cache -i inventory.ini playbook.yaml
```

Lastly, then one can run this to verify all is well:
```
ansible-playbook --check --flush-cache -i inventory.ini playbook.yaml
```

### Postgres cli
```
sudo -u postgres psql
```

### Lets Encyrpt
* Ths playbook uses this approach: [Reference](https://docs.bitnami.com/general/how-to/generate-install-lets-encrypt-ssl/#alternative-approach)
* This playbook will install lego and the cronjobs to renew the Let's Encrypt certs 
* To update lego, simply remove `/path/to/letsencrypt/lego` and rerun the playbook.
* `private_vars.yaml` allows one to use the server certs or Let's Encrypt certs
* The Let's Encrypt certs must be manually installed the first time for each domain as described below:

```
sudo /path/to/letsencrypt/lego --path /path/to/letsencrypt --http --http.webroot /path/to/acme_validation --domains "www.xyz.net"  --email 'johndoe@johndoe.com' run --preferred-chain 'ISRG Root X1'

# After certs are in place, update private_vars.yaml to 'use_lets_encrypt: yes' and 'lego_cron_disable: no' and rerun playbook

ansible-playbook --check --diff --tags letsencrypt,nginx-setup,gunicorn-setup --flush-cache -i inventory.ini playbook.yaml

# This will restart nginx.service. Check playbook output to confirm the certs are configured correctly
```

### References
* https://www.digitalocean.com/community/tutorials/how-to-set-up-django-with-postgres-nginx-and-gunicorn-on-debian-10
* https://docs.gunicorn.org/en/stable/deploy.html
* https://github.com/johnedstone/bitnami-wordpress-migration
