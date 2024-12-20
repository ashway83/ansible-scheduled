#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

if [ -z "${CRON_SCHEDULE}" ] && [ -z "${CRONTAB}" ]; then
    echo "Error: Either CRON_SCHEDULE or CRONTAB must be set" >&2
    exit 1
fi

if [ -z "${PLAYBOOK}" ]; then
    echo "Error: PLAYBOOK environment variable cannot be empty" >&2
    exit 1
fi

# Default command
DEFAULT_CRON_COMMAND="cd /ansible && ansible-playbook ${HOSTS:+-i $(printf '%s' "$HOSTS" | sed -e 's/[[:space:]]//g' -e 's/[^,]$/&,/')} ${PLAYBOOK}"
# Use CRON_COMMAND if set, otherwise use default
CRON_COMMAND=${CRON_COMMAND:-$DEFAULT_CRON_COMMAND}

# Generate SSH private key
ssh_key_file=~/.ssh/id_ed25519
if [ "$(echo "${SKIP_SSH_KEYGEN}" | tr '[:upper:]' '[:lower:]')" != "true" ] && [ ! -f "${ssh_key_file}" ]; then
    echo "Generating SSH key..."
    ssh-keygen -t ed25519 -f $ssh_key_file -N "" -C "ansible-scheduled-key-$(date +%Y%m%d%H%M%S)"
    echo "SSH key generated successfully."
    echo "Public key: $(cat "${ssh_key_file}.pub")"
fi

# Start scheduler
if [ $# -eq 0 ]; then
    if [ -z "${CRONTAB}" ]; then
        # Create a new crontab file with the provided schedule
        CRONTAB=/ansible/crontab.generated
        echo "${CRON_SCHEDULE} ${CRON_COMMAND}" > ${CRONTAB}
        echo "Created crontab file: ${CRONTAB}"
    else
        # Check if the crontab file exists
        if [ ! -f "${CRONTAB}" ]; then
            echo "Error: Crontab file not found at ${CRONTAB}" >&2
            exit 1
        fi
    fi
    # Start supercronic
    echo "Starting supercronic with crontab file: ${CRONTAB}"
    exec supercronic -no-reap -inotify -passthrough-logs "${CRONTAB}"
else
    # Execute specified command
    echo "Executing command: $*"
    exec "$@"
fi
