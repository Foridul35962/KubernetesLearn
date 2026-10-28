
#!/usr/bin/env bash

URL="http://localhost:8080/"

echo "Starting continuous GET requests to $URL"
echo "Press Ctrl+C to stop."

while true; do
  curl -s -o /dev/null "$URL" &
  wait
done
