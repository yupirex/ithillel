#!/usr/bin/env bash

Vars(){
    if [[ -n "$(find "$1" -type f)" ]]; then
        username=$(jq '.db.username' <"$1") username=${username//\"/}
        password=$(jq '.db.password' <"$1") password=${password//\"/}
        name=$(jq '.db.name' <"$1")         name=${name//\"/}
        sitename=$(jq '.sitename' <"$1")    sitename=${sitename//\"/}
        siteroot_dir=$(jq '.siteroot_dir' <"$1")
        siteroot_dir=${siteroot_dir//\"/}
    else exit
    fi
}

Install(){
    (apt -y install apache2 default-mysql-server php php7.3-mysql) \
        >/tmp/apt.log &
    bgapt=$!
#? a2enmod php7.3
    (wget -qO /tmp/latest.tar.gz https://wordpress.org/latest.tar.gz
    tar zxvf /tmp/latest.tar.gz -C /tmp
    mkdir -p "${siteroot_dir}"
    cp -r /tmp/wordpress/* "${siteroot_dir}/"
    cp "${siteroot_dir}"/{wp-config-sample.php,wp-config.php}) >/tmp/wget.log &
    bgwget=$!
    progress='-\|/' i=1
    while [[ -n "$(ps -p ${bgwget} -p ${bgapt} -o pid=)" ]]; do
        sleep 1
        echo -en "${progress:${i}:1} \\b\\b"
        i=$((i % 4 + 1))
    done
}

Config_mysql(){
    service mysql restart
    sed -i "s:database_name_here:${name}:; \
        s:username_here:${username}:; \
        s:password_here:${password}:; \
        s:localhost:${sitename}:" "${siteroot_dir}/wp-config.php"
    echo "127.0.0.1  ${sitename}" >>/etc/hosts
    mysql -u root -e "CREATE DATABASE ${name};"
    mysql -u root -e "GRANT ALL PRIVILEGES ON ${name}.* \
        TO \"${username}\"@\"localhost\" IDENTIFIED BY \"${password}\";"
    mysql -u root -e "FLUSH PRIVILEGES;"
    sleep 1
    service mysql restart
}

Config_apache(){
    sed -ri 's/(DirectoryIndex )(.*)(index.php )/\1\3\2/' \
        /etc/apache2/mods-enabled/dir.conf
    cd "/etc/apache2/sites-available" || return
    a2dissite 000-default.conf
    cat >"${sitename}.conf" <<EOF
<VirtualHost *:80>
    ServerAdmin admin@${sitename}
    ServerName ${sitename}
    ServerAlias ${sitename} *.${sitename}
    DocumentRoot ${siteroot_dir}
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
    a2ensite "${sitename}.conf"
    service apache2 reload
    grep "$(hostname -i).*${sitename}" /etc/hosts || \
        echo -e "$(hostname -i)\\t${sitename}" >>/etc/hosts
}

Config_bkp(){
    apt -y install cron
    count=$(jq ".bkp.count" <"$1") count=${count//\"/}
    n=$(jq '.bkp.time[]' <"$1"| wc -l)
    for (( i=0; i<n; i++ ));do
        crontime=$(jq ".bkp.time[$i]" <"$1") crontime=${crontime//\"/}
        echo "$crontime /bin/bash /usr/local/bin/bkp_${sitename}.sh" \
            >>/var/spool/cron/crontabs/root
    done
    cat >"/usr/local/bin/bkp_${sitename}.sh" <<EOF
#!/usr/bin/env bash

dir="/home/bkps/\$(date +%F_%T)"
mkdir -p "\$dir"
if [[ -n "\$(find "\$dir" -type d)" ]]; then
    tar -cvzf "\$dir/webroot.tar" "${siteroot_dir}"
    tar -cvzf "\$dir/apache.tar" "/etc/apache2/sites-available/${sitename}.conf"
    tar -cvzf "\$dir/logs.tar"  /var/log/apache2
    mysqldump -u${username} -p${password} ${name} >"\$dir/sql"
else exit
fi
if [[ "\$( find /home/bkps/* -type d | wc -l)" -gt ${count} ]]; then
    rm -r "\$(find /home/bkps/* -type d | head -n -${count})"
fi
EOF
}
#apt update
#apt install jq wget procps -y
#where json sets?
Vars /home/json
#Install
#Config_mysql
#Config_apache
Config_bkp /home/json
#rm -r /tmp/{latest.tar.gz,wordpress}
#echo "logs in /tmp/apt.log /tmp/wget.log"
exit
#-----=====-----=====-----=====-----=====-----=====-----=====-----=====-----=====

