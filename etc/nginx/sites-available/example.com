server {
    listen 127.0.0.1:8080;
 
    server_name example.com www.example.com;
    root /srv/www/example.com/public;
    access_log /srv/www/example.com/logs/access.log;
    error_log /srv/www/example.com/logs/error.log;
    rewrite ^/sitemap_index\.xml$ /index.php?sitemap=1 last;
    rewrite ^/([^/]+?)-sitemap([0-9]+)?\.xml$ /index.php?sitemap=$1&sitemap_n=$2 last;
 
        client_max_body_size 8M;
        client_body_buffer_size 128k;
        #The section below contains your WordPress rewrite rules
    location / {
                try_files $uri $uri/ /index.php?q=$uri&$args;
    }
        location /search { limit_req zone=one burst=3 nodelay; rewrite ^ /index.php; }
    fastcgi_intercept_errors off;
    location ~* \.(?:ico|css|js|gif|jpe?g|png)$ {
        expires max;
        add_header Pragma public;
        add_header Cache-Control "public, must-revalidate, proxy-revalidate";
    }
 
#sample 301 redirect
#   location /2011/06/26/permalink/ {
#       rewrite //2011/06/26/permalink/ http://example.com/2011/06/27/permalink_redirecting_to/ permanent;
#       }
 
#Send the php files to upstream to PHP-FPM
#This can also be added to separate file and added with an include
location ~ \.php {
        try_files $uri =404; #This line closes a big security hole
                             #see: http://forum.nginx.org/read.php?2,88845,page=3
        fastcgi_param  QUERY_STRING       $query_string;
        fastcgi_param  REQUEST_METHOD     $request_method;
        fastcgi_param  CONTENT_TYPE       $content_type;
        fastcgi_param  CONTENT_LENGTH     $content_length;
 
        fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
        fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
        fastcgi_param  REQUEST_URI        $request_uri;
        fastcgi_param  DOCUMENT_URI       $document_uri;
        fastcgi_param  DOCUMENT_ROOT      $document_root;
        fastcgi_param  SERVER_PROTOCOL    $server_protocol;
 
        fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
        fastcgi_param  SERVER_SOFTWARE    nginx;
 
        fastcgi_param  REMOTE_ADDR        $remote_addr;
        fastcgi_param  REMOTE_PORT        $remote_port;
        fastcgi_param  SERVER_ADDR        $server_addr;
        fastcgi_param  SERVER_PORT        $server_port;
        fastcgi_param  SERVER_NAME        $server_name;
 
        fastcgi_pass 127.0.0.1:9000;
}
 
}
