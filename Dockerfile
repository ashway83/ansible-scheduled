FROM alpine:3.21

RUN apk add --no-cache ansible-core openssh-client supercronic

RUN addgroup -g 10000 -S ansible && adduser -u 10000 -SD ansible -g ansible -h /ansible -G ansible

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER ansible:ansible

WORKDIR /ansible

COPY helloworld.yml /ansible/playbook.yml

ENV CRON_SCHEDULE="*/5 * * * *"
ENV PLAYBOOK=playbook.yml

ENTRYPOINT ["/entrypoint.sh"]
