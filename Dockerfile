FROM ruby:alpine

ENV MOBIUS_TIPBOT_TOKEN ""
ENV MOBIUS_TIPBOT_REDIS_URL "redis://localhost:6379/8"
ENV MOBIUS_TIPBOT_APP_PRIVATE_KEY ""
ENV MOBIUS_TIPBOT_CREDIT_ADDRESS ""
ENV MOBIUS_TIPBOT_RATE "0.1"
ENV MOBIUS_TIPBOT_NETWORK "test"

RUN apk add --no-cache git openssh g++ musl-dev make bash

WORKDIR /root

COPY bin /root/bin
COPY Gemfile /root
COPY Gemfile.lock /root
COPY slack.rb /root
COPY telegram.rb /root
COPY tip_bot.rb /root
COPY tip_bot /root/tip_bot
COPY locales /root/locales

RUN bundle install --without=development

CMD bin/telegram
