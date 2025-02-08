#/bin/bash
echo "请输入域名："
read domain
[ ! $domain ] && domain=test.com

echo "请输入数据库名，如果为空则默认为'WordPressDataBase'："
read wp_database_name
[ ! $wp_database_name ] && wp_database_name="WordPressDataBase"

echo "请输入数据库访问账号,如果为空则默认为'WordPressUserName'："
read wp_username
[ ! $wp_user_name ] && wp_user_name="WordPressUserName"

echo "请输入数据库访问密码,如果为空则默认为'WordPressPassWord'："
read wp_password
[ ! $wp_password ] && wp_password="WordPressPassWord"

echo "开始安装"
echo "更新源"
apt update -y
echo "更新系统"
apt upgrade -y

apt install nginx -y

systemctl start nginx

systemctl enable nginx

apt remove --purge apache2 -y

apt install mariadb-server -y

# 数据库连接参数
mysql -u root -p' ' -e "CREATE DATABASE $wp_database_name;"
mysql -u root -p' ' -e "CREATE USER '$wp_user_name'@localhost IDENTIFIED BY '$wp_database_name';"
mysql -u root -p' ' -e "GRANT ALL PRIVILEGES ON $wp_database_name.* TO $wp_user_name@localhost IDENTIFIED BY '$wp_password';"
mysql -u root -p' ' -e "FLUSH PRIVILEGES;"
mysql -u root -p' ' -e "EXIT;"

apt install php php-mysql php-gd php-xml php-mbstring php-curl php-fpm php-mysql php-imagick php-zip php-intl -y

printf "server {\n\
	listen 80; \n\
	server_name www.$domain $domain; \n\
	root /var/www/wordpress;\n\
	index index.php index.html index.htm;\n\
	location / { \n\
	try_files \$uri \$uri/ /index.php?\$args;\n\
	}\n\

	location ~ \.php$ {\n\
	include snippets/fastcgi-php.conf;\n\
	fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;\n\
	fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;\n\
	include fastcgi_params;\n\
	}\n\
	location ~ /\.ht {\n\
	deny all;\n\
	}\n\
}" > /etc/nginx/sites-available/wordpress

ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx

cd /tmp
curl -O https://wordpress.org/latest.tar.gz

tar xzvf latest.tar.gz
cp -a /tmp/wordpress/. /var/www/wordpress

chown -R www-data:www-data /var/www/wordpress

php_version_dir=$(find /etc/php/ -type d -mindepth 1 -maxdepth 1 | head -n 1)

sed -i 's/^max_execution_time.*\+=.*/max_execution_time = 1200/' $php_version_dir/fpm/php.ini
sed -i 's/^max_input_time.*\+=.*/max_input_time = 1200/' $php_version_dir/fpm/php.ini
sed -i 's/^upload_max_filesize.*\+=.*/upload_max_filesize = 2000M/' $php_version_dir/fpm/php.ini
sed -i 's/^post_max_size.*\+=.*/post_max_size = 2000m/' $php_version_dir/fpm/php.ini
sed -i 's/^upload_max_filesize.*\+=.*/upload_max_filesize = 1200/' $php_version_dir/fpm/php.ini

systemctl restart php8.2-fpm 

nginx_conf="/etc/nginx/nginx.conf"

if grep -q "client_max_body_size" "$nginx_conf"; then
    echo "配置文件中已经存在 client_max_body_size，跳过添加"
else
	sed -i '/^[[:space:]]*http {/a \    client_max_body_size 2000m;' "$nginx_conf"
	echo "已成功在 http{} 块中添加 client_max_body_size 2000m;"

systemctl restart nginx

echo "完成安装!"
