FROM alpine:3.18.0

# Install OpenSSH
RUN apk add --no-cache openssh

# Define the environment variable
ARG SSH_PRIVATE_KEY
# Create the .ssh directory if it doesn't exist
RUN mkdir -p /root/.ssh
# Write the private key content to id_rsa file
RUN echo "$SSH_PRIVATE_KEY" | tr -d '\r' > /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa

# Define the environment variable for the GitLab threedytech private key
ARG SSH_PRIVATE_KEY_GIT
# Write the private key content to id_git_rsa file
RUN echo "$SSH_PRIVATE_KEY_GIT" | tr -d '\r' > /root/.ssh/id_git_rsa && chmod 600 /root/.ssh/id_git_rsa
# Add the configuration for the git server; this is used by git to clone repositories from the git server and operate on them
RUN echo -e "Host git.my_company.com\n  Hostname 192.168.123.123\n  PreferredAuthentications publickey\n  IdentityFile /root/.ssh/id_git_rsa\n  StrictHostKeyChecking no" >> /root/.ssh/config
# Add the SSH host key to known hosts
RUN mkdir -p ~/.ssh && ssh-keyscan git.my_company.com >> ~/.ssh/known_hosts

CMD ["sh"]
