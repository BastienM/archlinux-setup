FROM archlinux/base

ENV ANSIBLE_CONFIG /tmp/playbook/.ansible.cfg

RUN pacman -Syu ansible --noconfirm

VOLUME ["/tmp/playbook"]

CMD ["ansible-playbook", "-i", "localhost", "/tmp/playbook/playbook.yml"]
