# Second SSH Key for git in docker container

## Scenario

You already have a `docker` container with a SSH key configured. If you want to use a second SSH key for git usage, how do you do that when your your first SSH key already is the default one?

For a guide on how to configure you SSH key in docker, see [Configure docker container with SSH access](https://github.com/Frunza/configure-docker-container-with-ssh-access)

## Prerequisites

A Linux or MacOS machine for local development. If you are running Windows, you first need to set up the *Windows Subsystem for Linux (WSL)* environment.

You need `docker cli` and `docker-compose` on your machine for testing purposes, and/or on the machines that run your pipeline.
You can check both of these by running the following commands:
```sh
docker --version
docker-compose --version
```

Set the following environment variable for SSH access:
- TARGET_MACHINE_SSH_PRIVATE_KEY
- SSH_PRIVATE_KEY_GIT
You can name these variables however you want. For convenience, you can add them directly to your profile. This can look like this, for example:
```sh
export SSH_PRIVATE_KEY_GIT="-----BEGIN OPENSSH PRIVATE KEY-----
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
aaaaaaaaaaa
-----END OPENSSH PRIVATE KEY-----"
```
Note the syntax: it needs double quotation marks at the beginning and the end of the ssh key value.

Note: if you use `GitLab`, the value of the environment variable must contain the content only, without the double quotation marks.

## Implementation

When building the docker image, pass 2 arguments to it to provide the value of the `TARGET_MACHINE_SSH_PRIVATE_KEY` and `SSH_PRIVATE_KEY_GIT` environment variables:
```sh
--build-arg SSH_PRIVATE_KEY="$TARGET_MACHINE_SSH_PRIVATE_KEY" SSH_PRIVATE_KEY="$SSH_PRIVATE_KEY"
```

Let's assume your current `dockerfile` looks like
```sh
FROM alpine:3.18.0

# Install OpenSSH
RUN apk add --no-cache openssh

# Define the environment variable
ARG SSH_PRIVATE_KEY
# Create the .ssh directory if it doesn't exist
RUN mkdir -p /root/.ssh
# Write the private key content to id_rsa file
RUN echo "$SSH_PRIVATE_KEY" | tr -d '\r' > /root/.ssh/id_rsa && chmod 600 /root/.ssh/id_rsa

CMD ["sh"]
```

Add the following in your `dockerfile`:
```sh
ARG SSH_PRIVATE_KEY_GIT
RUN echo "$SSH_PRIVATE_KEY_GIT" | tr -d '\r' > /root/.ssh/id_git_rsa && chmod 600 /root/.ssh/id_git_rsa
```
This will copy the value of `SSH_PRIVATE_KEY_GIT` to a file named `id_git_rsa` in the location for SSH keys.

Now you have to tell git how to use the `id_git_rsa` SSH key instead of the default one. To do this, you can use a configuration file. Let's assume that your `git` server is reachable at `git.my_company.com`:
```sh
RUN echo -e "Host git.my_company.com\n  Hostname 192.168.123.123\n  PreferredAuthentications publickey\n  IdentityFile /root/.ssh/id_git_rsa\n  StrictHostKeyChecking no" >> /root/.ssh/config
RUN mkdir -p ~/.ssh && ssh-keyscan git.my_company.com >> ~/.ssh/known_hosts
```

## Usage

Navigate to the root of the git repository and run the following commands:
```sh
sh run.sh 
```

The following happens:
1) the first command builds the docker image, passing the private key value as an argument and tagging it as *sshaccess*
2) the docker image sets up the SSH access by copying the value of the `SSH_PRIVATE_KEY` and `SSH_PRIVATE_KEY_GIT` argument to the standard location for SSH keys
3) the second command uses docker-compose to create and run the container. The container runs an SSH check against a target machine and prints some output to inform whether it was successful or not. Commands to clone repositories from `git.my_company.com` and operate on them will also work.
