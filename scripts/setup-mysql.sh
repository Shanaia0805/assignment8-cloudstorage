#!/bin/bash
sudo apt-get update
sudo apt-get install -y mysql-server mysql-client unzip curl


# install 
sudo systemctl start mysql
# Wait for MySQL to start
sleep 5

# Set the root/admin user to MYSQL_USER and MYSQL_PASS
# First, ensure root user exists and is accessible
sudo mysql -e "CREATE USER IF NOT EXISTS 'root'@'localhost' IDENTIFIED BY 'root';"

# Change root user to the given MYSQL_USER and MYSQL_PASS
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';"

# Create your MySQL user and grant privileges (this is not the root user anymore)
sudo mysql -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASS}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'localhost' WITH GRANT OPTION;"

# Make sure root user can still access the database after changing its password
sudo mysql -e "FLUSH PRIVILEGES;"

#  save encrypt credentials in .my.cnf (for mysqldump) 
cat << EOF > ~/.my.cnf
[client]
user="${MYSQL_USER}"
password="${MYSQL_PASS}"
host=localhost
EOF

#  import example database (movies table only to keep the size down)
gunzip -c  recommend.sql.gz | mysql 

# installing  aws cli (for S3) 
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
mkdir -p .aws

# install the aws credentials and config for aws cli to work. 
cat << EOF > ~/.aws/credentials
[default]
aws_access_key_id=${AWS_ACCESS_KEY_ID} 
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY} 
EOF

cat << EOF > ~/.aws/config
[default]
region=us-west-2
output=json
EOF

cat << EOF > ~/config.sh
export MYSQL_S3_BUCKET=${S3_BUCKET}
export DB_NAME="recommend"
export DB_TABLES="movies"
export RETENTION_DAYS=1
EOF

sudo apt update && sudo apt install -y mysql-client gzip

# Ensure backup script is executable
chmod +x /home/ubuntu/backup_mysql.sh

# Schedule cron job to run backup every hour
(crontab -l 2>/dev/null; echo "0 * * * * /home/ubuntu/backup_mysql.sh") | crontab -

echo "all done"  
