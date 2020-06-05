FROM alpine
RUN apk update && apk add python3 py3-pip php composer php-zip php-dom \
    php-tokenizer php-xmlwriter php-xml php-simplexml bash neovim git  \
    nginx php-fpm supervisor php-pdo_mysql php-curl
RUN mkdir /run/nginx
ADD predict-api /predict-api
RUN chown nobody:nobody /predict-api/storage/logs/
ADD conf/nginx/predict-api.conf /etc/nginx/conf.d/predict-api.conf
RUN rm /etc/nginx/conf.d/default.conf
ADD conf/supervisor/predict-api.ini /etc/supervisor.d/predict-api.ini
RUN pip3 install git+https://github.com/coderanger/supervisor-stdout
ADD entrypoint.sh /entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/supervisord.conf"]
