version: "2" 
services:

  site:
    image: wordpress:latest
    container_name: site
    environment:
      WORDPRESS_DB_HOST: "db"
      WORDPRESS_DB_USER: "myuser"
      WORDPRESS_DB_PASSWORD: "passwd"
      WORDPRESS_DB_NAME: "wp"
    ports:
      - 8081:80
    volumes:
      - "wpdata:/var/www/html:rw"
      #- "/tmp/wp:/var/www/html"
    depends_on:
      - db
    networks:
      - mysite
      #mysite:
        #ipv4_address: 172.29.0.3

  web:
    image: nginx
    container_name: web
    volumes:
      - /tmp/nginx/templates/nginx.conf:/etc/nginx/conf.d/default.conf
    ports:
      - "80:80"
    networks:
      - mysite
      #mysite:
        #ipv4_address: 172.29.0.4
    depends_on:
      - site
    links:
      - site
    restart: always

  db: 
    image: mysql:latest
    container_name: db
    volumes:
      - "dbdata:/var/lib/mysql"
    environment:
      MYSQL_DATABASE: "wp"
      MYSQL_ROOT_PASSWORD: "strongpass"
      MYSQL_USER: "myuser"
      MYSQL_PASSWORD: "passwd"
    networks:
      - mysite
      #mysite:
        #ipv4_address: 172.29.0.2

networks:
  mysite:
    #mysite:
    #driver: bridge
    #ipam:
      #driver: default
      #config:
        #- subnet: 172.29.0.0/24
        #  gateway: 172.29.0.250

volumes:
  wpdata:
  dbdata:
