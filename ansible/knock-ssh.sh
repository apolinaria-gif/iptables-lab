
#!/bin/bash

set -e

TARGET="192.168.255.1"

echo "Sending port knocking sequence..."

knock -d 300 "$TARGET" 7000 8000 9000

echo "Port knocking sequence sent."
echo "Connecting to SSH..."

exec ssh \
  -i /home/vagrant/.ssh/inetRouter_key \
  -o IdentitiesOnly=yes \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  vagrant@"$TARGET"
