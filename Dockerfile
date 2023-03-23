FROM ruby:2.7.2
RUN apt-get update -qq \
  && apt-get install -y --no-install-recommends -qq \
  nano build-essential libpq-dev locales default-mysql-client zip \
  libcurl4-gnutls-dev \
  && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get update && apt-get install -y nodejs && npm install --global yarn
# ...
RUN apt-get update -qq && apt-get install -y freetds-dev
# ...

COPY ./Gemfile ./Gemfile
COPY ./Gemfile.lock ./Gemfile.lock

RUN gem install bundler -v 2.2.33
RUN bundle config --local build.sassc --disable-march-tune-native
RUN bundle install
WORKDIR /app

RUN rm -rf tmp && mkdir tmp
RUN rm -rf log && mkdir log

RUN yarn install
COPY . ./

EXPOSE 3000
CMD rails s -b '0.0.0.0'

