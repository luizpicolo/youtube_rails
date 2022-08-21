FROM ruby:3.1.2
 
WORKDIR /app
# ADD Gemfile /app/Gemfile
# ADD Gemfile.lock /app/Gemfile.lock

# RUN bundle install
ADD . /app