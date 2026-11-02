# what is this ?

A bare bone odoo capable sandbox for running AI agents in a containerized environment.
The container is (should be) isolated from the host network and filesystem,
but can be given access to a project directory and a persistent state volume.
It also has access to internet, so this is not suitable for handling sensitive data.

## build

docker build -t ai-sandbox .

## run

NET_ADMIN is needed only at startup to block LAN/host access; it is dropped before the shell starts.

docker run -it --rm \
  --cap-add=NET_ADMIN \
  -v /path/to/your/actual/project:/workspace \
  -v ai_agent_state:/state \
  -e COPILOT_GITHUB_TOKEN \
  -e PUBLISH_PORTS="8069 8000" \
  -p 127.0.0.1:8069:8069 \
  -p 127.0.0.1:8000:8000 \
  ai-sandbox

Ports listed in `PUBLISH_PORTS` (space-separated, ranges like `8000:8010` allowed) are forwarded from the
container's network interface to `127.0.0.1` inside it, so services bound to localhost (OAuth login
callbacks, test web servers) are reachable from the host browser. Each port must also be published with `-p`.
Both settings are fixed at `docker run` time; this requires rebuilding the image and starting a new container.
Pass the same port numbers on both sides (host:container) so redirect URLs such as `http://localhost:PORT/...` work.

## wipe memory

docker volume rm ai_agent_state
