FROM ruby:2.5.1-alpine

ENV HOME /production
WORKDIR $HOME

RUN apk --update add \
  build-base \
  libxslt-dev \
  tzdata \
  imagemagick \
  && rm -rf /var/cache/apk/*

COPY . $HOME

RUN bundle config build.nokogiri --use-system-libraries
RUN bundle install --without development test

ENV RAILS_ENV production
EXPOSE 3000

CMD ["rails", "server"]
