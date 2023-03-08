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

### Postgres notes

#### psql (command line)
Examples:
```
sudo -u postgres psql
psql -h localhost -U <user> -d <database> -W
```

#### Create new db, after dropping
```
ansible-playbook --check --diff --tags create-db-grant-perms --flush-cache -i inventory.ini playbook.yaml
```

#### pg_dump and pg_restore

* [reference AWS](https://docs.aws.amazon.com/dms/latest/sbs/chap-manageddatabases.postgresql-rds-postgresql-full-load-pd_dump.html)
* [reference random](https://simplebackups.com/blog/postgresql-pgdump-and-pgrestore-guide-examples/#see-a-pg_dump-example)

```
# Dump database in sql format
pg_dump --schema <the schema> -h localhost -U <db_user> -b -v -f filename_output_forrestore.sql -d <db_name>

# Dump db in format for restore
pg_dump --schema <the schema> -h localhost -U <db_user> -Fc -b -v -f filename_output_forrestore.custom -d <db_name>

# select tables (data, schema, all) in plain text (add -Fc for use with pg_restore, and use .custom)
pg_dump --schema-only  -t 'schema."table_name"' -t 'schema."pattern"*'  --schema schema -h localhost -U user  -b -v -f finename.sql -d <db_name>
pg_dump --data-only  -t 'schema."table_name"' -t 'schema."pattern"*'  --schema schema -h localhost -U user  -b -v -f finename.sql -d <db_name>
pg_dump -t 'schema."table_name"' -t 'schema."pattern"*'  --schema schema -h localhost -U user  -b -v -f finename.sql -d <db_name>
```

#### Restoring Sequence
```
sudo -u postgres psql and do 'DROP DATABASE "name_of_database";
ansible-playbook --skip-tags db_user --tags postgres --diff --flush-cache -i inventory.ini playbook.yaml

### then
pg_restore -h localhost -U username -W -d dbname  file_to_pg_dump_no_django.custom 
### And, this skips non-django tables but creates django tables
python manage.py migrate --fake-initial  --settings config.settings_whatever
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
