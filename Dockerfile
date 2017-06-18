FROM ubuntu:16.04

RUN apt-get update && apt-get install --no-install-recommends -y postgresql-client-9.5 python-pip python-setuptools && \
  pip install awscli && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

ENV PGDUMP_OPTIONS -Fc --no-acl --no-owner
ENV PGDUMP_DATABASE **None**

ENV AWS_ACCESS_KEY_ID **None**
ENV AWS_SECRET_ACCESS_KEY **None**
ENV AWS_BUCKET **None**
ENV AWS_REGION **None**

ENV PREFIX **None**

ADD run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
