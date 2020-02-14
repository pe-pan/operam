#setup PSQL DB
sudo postgresql-setup initdb
sudo systemctl start postgresql
sudo systemctl enable postgresql

sudo sed -i -- 's|host    all             all             127.0.0.1/32            ident|host    all             all             127.0.0.1/32            trust|g' /var/lib/pgsql/data/pg_hba.conf
sudo service postgresql restart

sudo su - postgres <<EOT
psql <<EOF
\x
create database operam;
create user operam with encrypted password 'Cloud@123';
grant all privileges on database operam to operam;
\q
EOF
exit
EOT
