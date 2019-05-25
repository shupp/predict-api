FROM alpine
RUN apk update && apk add php composer php-zip php-dom php-tokenizer \
    php-xmlwriter php-xml php-simplexml bash neovim git

ADD predict-api /predict-api
