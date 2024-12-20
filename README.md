# ansible-scheduled

This project provides a streamlined Docker image for running scheduled Ansible tasks. The focus is on offering a lightweight, easily configurable solution without sacrificing advanced customization options. You can start quickly with a single-line command or customize extensively using environment variables and volume mounts.

The `ansible-scheduled` Docker images are multi-platform, supporting all Alpine Linux architectures. This includes amd64, arm64, ppc64le, s390x, 386, armv6, and armv7, ensuring compatibility with a wide range of hardware platforms. When pulling the image, Docker automatically selects the appropriate version for your system's architecture, ensuring seamless deployment across different types of infrastructure.

## Getting Started

The `ansible-scheduled` image includes default configuration values, enabling a quick start with minimal setup. You can run the container by specifying only essential parameters and relying on defaults for the rest. By default, it schedules the playbook `/ansible/playbook.yml` to run every 5 minutes. For convenience, when the container is started for the first time, an SSH key pair is automatically generated in the home directory of the user under which the container is running (by default, `/ansible/.ssh`).

### Docker

To get started with a basic setup, you can use this minimal command:

``` Shell
docker run -it -v ./myplaybook.yml:/ansible/playbook.yml \
	-e HOSTS="192.168.0.1,192.168.0.2," \
	ansible-scheduled
```

The schedule can be specified inline by setting the `CRON_SCHEDULE` environment variable. The startup script within the container will automatically create a `crontab.generated` file. The following command creates a container that runs the playbook every minute:

``` Shell
docker run -it -v ./myplaybook.yml:/ansible/playbook.yml \
	-e HOSTS="192.168.0.1,192.168.0.2," \
	-e CRON_SCHEDULE="*/1 * * * *" \
	ansible-scheduled
```

Alternatively, the `CRONTAB` variable can be set to point to a custom crontab file, allowing multiple playbooks and custom commands to be scheduled. For this scenario, it is recommended that you mount a host folder or a volume containing the configuration files and playbooks.

``` Shell
docker run -it -v ./ansible:/ansible \
	-e HOSTS="192.168.0.1,192.168.0.2," \
	-e CRONTAB="/ansible/crontab" \
	ansible-scheduled
```

**Important:** By default, the container runs under a non-root user, `ansible`. To ensure this user can access mounted host directories, you should adjust the permissions of the host directory before mounting or specify another user.

### Docker Compose

Below is an example of `docker-compose.yml` file:

``` YAML
services:
  ansible-scheduled:
    image: ansible-scheduled
    restart: unless-stopped
    volumes:
      - ansible-data:/ansible
    environment:
      - CRONTAB=/ansible/crontab
      - ANSIBLE_INVENTORY=/ansible/myinventory.yml
      - ANSIBLE_PRIVATE_KEY_FILE=/ansible/ssh_key
      - ANSIBLE_HOST_KEY_CHECKING=false

volumes:
  ansible-data:
```

This configuration:

- Uses a named volume `ansible-data` to store configuration files
- Sets a custom crontab file and inventory location
- Specifies the location of the SSH private key file
- Disables SSH host key checking (see note below)
- Ensures the container restarts automatically unless explicitly stopped

**Important:** The standard Ansible `ANSIBLE_HOST_KEY_CHECKING=false` environment variable is set to facilitate the initial connection to hosts when running for the first time. This allows the hosts to be added to the `known_hosts` file automatically. For security reasons, this parameter must be removed after the initial run, once the host keys are stored.

Before starting the container, prepare your custom crontab and inventory files in the directory that will be mounted to `/ansible` in the container.

To start the container:

``` Shell
docker-compose up -d
```

You can view logs with `docker-compose logs` and stop the container with `docker-compose down`.

## Testing

For convenience and quick testing, a simple "hello world" `playbook.yml` is included in the container. This allows you to test the basic functionality of the container without providing your own playbook. The test playbook simply prints "Hello, World!" to the console.

To use this test playbook, you can run the container without mounting your own playbook:

```shell
docker run -it -e HOSTS="localhost," ansible-scheduled
```

This will run the included test playbook on the localhost every 5 minutes (using the default schedule). You should see "Hello, World!" printed in the logs at each execution.

Once you've confirmed that the container is working as expected with the test playbook, you can replace it with your own playbook by mounting it as described in the "Getting Started" section.

## Configuration

### Environment Variables

You can customize the behavior of the container using the following environment variables:

- `CRONTAB`: Path to a custom crontab file. When set, this takes precedence over `CRON_SCHEDULE`.
- `CRON_SCHEDULE`: The cron schedule for running the playbook (default: `*/5 * * * *`). This is ignored if `CRONTAB` is set.
- `CRON_COMMAND`: Allows overriding the default command that runs on the cron schedule. This is relevant only when `CRON_SCHEDULE` is set.
- `HOSTS`: Allows specifying a comma-separated list of hosts for the Ansible inventory.
- `PLAYBOOK`: The name of the Ansible playbook to run (default: `playbook.yml`). Note that it will have no effect if a custom `CRON_COMMAND` is specified.
- `SKIP_SSH_KEYGEN`: Set to "true" (case-insensitive) to skip SSH key generation.

In addition to these container-specific variables, you can use any of the standard Ansible environment variables to further customize the behavior. Some commonly used Ansible variables include:

- `ANSIBLE_INVENTORY`: Specifies the path to the inventory file.
- `ANSIBLE_PRIVATE_KEY_FILE`: Sets the path to the SSH private key file.
- `ANSIBLE_CONFIG`: Specifies the path to the Ansible configuration file.

For a complete list of Ansible environment variables and their descriptions, refer to the [Ansible documentation](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#environment-variables).

### SSH Key

The container generates an Ed25519 SSH key upon its first startup. The public key is printed to the container logs. You can use this key to set up SSH access to your target hosts.

If you prefer to use existing SSH keys instead of the auto-generated ones, you can set the `ANSIBLE_PRIVATE_KEY_FILE` environment variable to the path of your private key file within the container. Ensure that you mount the directory containing your existing SSH key and update the file permissions if necessary.

## Building Custom Images

To build and use your own custom image:

1. Clone this repository:
   ``` Shell
   git clone https://github.com/ashway83/ansible-scheduled.git
   cd ansible-scheduled
   ```

2. Customize the container image.

3. Build the Docker image:
   ``` Shell
   docker build -t my-ansible-scheduled .
   ```

4. Run the container:
   ``` Shell
   docker run -d --name my-ansible-scheduled my-ansible-scheduled
   ```
