FROM ruby:2.5
MAINTAINER Hannes Schaller <hannes.schaller@apa.at>

ENV CI_COMMIT_REF_NAME=octodiff

RUN mkdir -p vendor/r10k && ln -s ${PWD}/vendor/r10k /root/.r10k
RUN mkdir -p ~/.ssh
RUN echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config
RUN apt-get update && apt-get install -y rsync cmake

WORKDIR /controlrepo

ADD Gemfile /controlrepo/
RUN bundle install --system
RUN puppet module install puppetlabs-stdlib
# This is where the script part begins
ADD . /controlrepo
RUN bundle exec onceover init
ADD ubuntu16.puppettest.apa.at.json spec/factsets/ubuntu16.puppettest.apa.at.json
RUN puppet resource file_line onceoveryaml path=/controlrepo/spec/onceover.yaml line="  - ubuntu16.puppettest.apa.at" after='^nodes:'

RUN bundle exec onceover run diff --trace -f $CI_COMMIT_REF_NAME -t production --debug -n "ubuntu16.puppettest.apa.at,Debian-6.0.10-64" -c role::database_server --debug
CMD /bin/bash
