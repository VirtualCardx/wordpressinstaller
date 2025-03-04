#/bin/bash
echo "请输入数据库名，如果为空则默认为'WordPressDataBase'："
read wp_database_name
[ ! $wp_database_name ] && wp_database_name="WordPressDataBase"

echo "请输入数据库访问账号,如果为空则默认为'WordPressUserName'："
read wp_username
[ ! $wp_user_name ] && wp_user_name="WordPressUserName"

echo "请输入数据库访问密码,如果为空则默认为'WordPressPassWord'："
read wp_password
[ ! $wp_password ] && wp_password="WordPressPassWord"



while true; do
    read -p "Do you wish to install this mariadb-server?" yn
    case $yn in
        [Yy]* ) make install; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# 数据库连接参数
mysql -u root -p' ' -e "CREATE DATABASE $wp_database_name;"
mysql -u root -p' ' -e "CREATE USER '$wp_user_name'@localhost IDENTIFIED BY '$wp_database_name';"
mysql -u root -p' ' -e "GRANT ALL PRIVILEGES ON $wp_database_name.* TO $wp_user_name@localhost IDENTIFIED BY '$wp_password';"
mysql -u root -p' ' -e "FLUSH PRIVILEGES;"
mysql -u root -p' ' -e "EXIT;"
while true; do
    read -p "Do you wish to install this mariadb-server?" yn
    case $yn in
        [Yy]* ) make install; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done



echo "完成安装!"
