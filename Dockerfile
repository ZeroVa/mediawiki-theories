FROM mediawiki:1.42

COPY theme /var/www/html/consciousness-theme
COPY localsettings.d /var/www/html/localsettings.d
COPY init/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh \
  && mkdir -p /data

VOLUME ["/data", "/var/www/html/images"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
