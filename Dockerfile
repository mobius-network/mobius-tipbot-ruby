FROM ruby:alpine

# Provide private github token
ARG BUNDLE_GITHUB__COM

ENV MOBIUS_TIPBOT_REDIS_URL "redis://localhost:6379/8"
ENV MOBIUS_TIPBOT_SLACK_API_TOKEN ""
ENV MOBIUS_TIPBOT_TELEGRAM_API_TOKEN ""
ENV MOBIUS_TIPBOT_APP_PRIVATE_KEY ""
ENV MOBIUS_TIPBOT_CREDIT_ADDRESS ""
ENV MOBIUS_TIPBOT_RATE "1"

RUN apk add --no-cache git openssh g++ musl-dev make

WORKDIR /root

COPY Gemfile /root
COPY Gemfile.lock /root
COPY slack.rb /root
COPY tip_bot.rb /root
COPY tip_bot /root/tip_bot
COPY locales /root/locales

RUN bundle install --without=development

# Slack is default
CMD bundle exec ruby slack.rb
