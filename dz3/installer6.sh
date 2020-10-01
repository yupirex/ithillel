#!/usr/bin/env bash

Check_install(){
    file1="$(mktemp)" file2="$(mktemp)"
    sed "s/ /\\n/g" <<<"$*" >>"$file1"
    read -ra install_pack <<<"$*"
    apt list --installed "${install_pack[@]}" 2>/dev/null |\
        sed -n "/Listing/,$ s|/.*||p" >"$file2"
    not_install="$(grep -vf "$file2" "$file1")"
    [[ -n "$not_install" ]] && echo "Instaling $not_install"
    rm "$file1" "$file2"
}

Install(){
    Check_install jq wget procps
    [[ -n "$not_install" ]] && apt install -y "$not_install"
    Check_install apache2 default-mysql-server php php7.3-mysql cron
    [[ -n "$not_install" ]] && (apt -y install "$not_install") > /tmp/apt.log &
    bgapt=$!
    echo Downloading latest.tar.gz
    (wget -qO /tmp/latest.tar.gz https://wordpress.org/latest.tar.gz
    tar zxvf /tmp/latest.tar.gz -C /tmp) >/tmp/wget.log &
    bgwget=$!
    # Ожидаем окончания выполнения фоновых задач + прогрес бар
    progress=' -\|/' i=1
    while [[ -n "$(ps -p ${bgwget} -p ${bgapt} -o pid=)" ]]; do
        sleep 1
        echo -en "${progress:${i}:1} \\b\\b"
        i=$((i % 4 + 1))
    done
}

Vars(){
    username=$(jq -r '.db.username' <<<"$1")
    password=$(jq -r '.db.password' <<<"$1")
    name=$(jq -r '.db.name' <<<"$1")
    sitename=$(jq -r '.sitename' <<<"$1")
    siteroot_dir=$(jq -r '.siteroot_dir' <<<"$1")
}

Config_wp(){
    echo Config wordpress
    mkdir -p "${siteroot_dir}"
    cp -r /tmp/wordpress/* "${siteroot_dir}/"
    cp "${siteroot_dir}"/{wp-config-sample.php,wp-config.php}
    sed -i "s:database_name_here:${name}:; \
        s:username_here:${username}:; \
        s:password_here:${password}:" "${siteroot_dir}/wp-config.php"

}

Config_mysql(){
    mysql -u"$username" -p"$password" -e"use $name" && return
    echo Config mysql-server
    service mysql restart
    mysql -u root -e "CREATE DATABASE ${name}; \
        GRANT ALL PRIVILEGES ON ${name}.* \
        TO \"${username}\"@\"localhost\" IDENTIFIED BY \"${password}\";"
    sleep 1
    service mysql restart
}

Config_apache(){
    echo Config apache2
    a2dissite ./*
    service apache2 restart
    sed -ri 's/(DirectoryIndex )(.*)(index.php )/\1\3\2/' \
        /etc/apache2/mods-enabled/dir.conf
    cd "/etc/apache2/sites-available" || return
    i=80
    while lsof -i -P -n |grep -q "$i.*LISTEN"; do
        ((i++))
    done
    cat >"${sitename}.conf" <<EOF
<VirtualHost *:80>
    ServerAdmin admin@${sitename}
    ServerName ${sitename}
    ServerAlias ${sitename} *.${sitename}
    DocumentRoot ${siteroot_dir}
     <Directory ${siteroot_dir}>
        AllowOverride All
    </Directory>
    ErrorLog ${siteroot_dir}/error.log
    CustomLog ${siteroot_dir}/access.log combined
</VirtualHost>
EOF
    a2ensite "${sitename}.conf"
    service apache2 reload
    grep "$(hostname -i).*${sitename}" /etc/hosts || \
        echo -e "$(hostname -i)\\t${sitename}" >>/etc/hosts
}

Config_bkp(){
    service cron restart
    count=$(jq -r ".bakup.count" <<<"$1")
    n=$(jq '.bakup.time|length' <<<"$1")
    for (( i=0; i<n; i++ ));do
        crontime=$(jq ".bakup.time[$i]" <<<"$1") crontime=${crontime//\"/}
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
    mysqldump -u${username} -p${password} ${name} >"\$dir/sql"
else exit
fi
if [[ "\$( find /home/bkps/* -type d | wc -l)" -gt ${count} ]]; then
    rm -r "\$(find /home/bkps/* -type d | head -n -${count})"
fi
EOF
}

# Считываем эл-ты масива и для каждого запускаем установку
Read_file(){
    while read -r LINE; do
        Vars "$LINE"
#        Config_wp
#        Config_mysql
        Config_apache
        Config_bkp "$LINE"
    done < <(jq -c .[] < "$1")
}

# Установка необходимых пакетов
#apt update
#Install


# Путь к настройкам из json файла можно передать параметром в скрипт или указать
# абсолютный путь к json файлу. Проверяем возможность прочитать файл

jfile="/home/dev/dz3/json.json"
if [[ -r "$1" ]]; then
    Read_file "$1"
elif [[ -r "$jfile" ]]; then
    Read_file "$jfile"
else
    echo "The file does not exist or cannot be read"
fi

exit
#-----=====-----=====-----=====-----=====-----=====-----=====-----=====-----=====
