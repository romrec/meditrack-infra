FROM python:3.11-slim

# Installer Ansible et les dépendances
RUN apt-get update && apt-get install -y ansible openssh-client

# Créer le répertoire SSH
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh

# Copier les fichiers
WORKDIR /ansible
COPY . .

# Configurer la clé SSH
COPY --chmod=600 ansible/meditrack-key-new.pem /root/.ssh/meditrack-key-new.pem
RUN chmod 600 /root/.ssh/meditrack-key-new.pem && \
    touch /root/.ssh/known_hosts

CMD ["ansible-playbook", "-i", "inventory.ini", "playbook.yml"]