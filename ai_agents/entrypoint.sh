#!/bin/bash
set -e

# 0. Block LAN / host access (loopback stays open for local Postgres), then drop NET_ADMIN
#    so even root in the container cannot undo the rules. Requires --cap-add=NET_ADMIN.
if [ -z "$FIREWALL_DONE" ]; then
    # Docker's internal resolver returns empty answers here, so glibc never falls through to later servers.
    # Put public resolvers first (they are not covered by the LAN block below); keep the original after them.
    {
        echo "nameserver 1.1.1.1"
        echo "nameserver 8.8.8.8"
        grep -vE '^nameserver (1\.1\.1\.1|8\.8\.8\.8)$' /etc/resolv.conf
    } >/tmp/resolv.new
    cat /tmp/resolv.new >/etc/resolv.conf && rm -f /tmp/resolv.new
    iptables -A OUTPUT -o lo -j ACCEPT
    iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    # Docker's DNS resolver is usually a private IP; allow port 53 to it only
    for ns in $(awk '/^nameserver/ {print $2}' /etc/resolv.conf | grep -v ':'); do
        iptables -A OUTPUT -d "$ns" -p udp --dport 53 -j ACCEPT
        iptables -A OUTPUT -d "$ns" -p tcp --dport 53 -j ACCEPT
    done
    for net in 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 169.254.0.0/16 100.64.0.0/10 127.0.0.0/8 224.0.0.0/4; do
        iptables -A OUTPUT -d "$net" ! -o lo -j REJECT
    done
    if ip6tables -L >/dev/null 2>&1; then
        ip6tables -A OUTPUT -o lo -j ACCEPT
        ip6tables -A OUTPUT -d fc00::/7 -j REJECT
        ip6tables -A OUTPUT -d fe80::/10 -j REJECT
    fi
    # Inbound: make ports published with `docker run -p` reach services bound to 127.0.0.1 inside the container
    # (OAuth login callback, dev web servers). PUBLISH_PORTS is a space-separated list of ports or ranges, e.g. "1455 3000 8000:8010".
    if [ -n "$PUBLISH_PORTS" ]; then
        sysctl -qw net.ipv4.conf.all.route_localnet=1 || echo "warning: could not enable route_localnet" >&2
        for p in $PUBLISH_PORTS; do
            iptables -t nat -A PREROUTING ! -i lo -p tcp --dport "$p" -j DNAT --to-destination 127.0.0.1
        done
    fi
    export FIREWALL_DONE=1
    exec capsh --drop=cap_net_admin -- -c 'exec "$0" "$@"' "$0" "$@"
fi

# 1. Force all agent state (auth, history, config) into the persistent volume
mkdir -p /state/home
export HOME=/state/home

# 2. Setup persistent PostgreSQL data directory inside the state volume
PG_VERSION=$(ls /usr/lib/postgresql/ | head -n 1)
PG_DATA="/state/pgdata"

if [ ! -f "$PG_DATA/PG_VERSION" ]; then
    echo "Initializing fresh PostgreSQL database in persistent state..."
    mkdir -p "$PG_DATA"
    chown -R postgres:postgres "$PG_DATA"

    # Initialize DB
    sudo -u postgres /usr/lib/postgresql/${PG_VERSION}/bin/initdb -D "$PG_DATA" >/dev/null

    # Start Postgres temporarily to set up the superuser
    sudo -u postgres /usr/lib/postgresql/${PG_VERSION}/bin/pg_ctl -D "$PG_DATA" -w start >/dev/null

    # Create an all-powerful user for the AI agent to use
    sudo -u postgres psql -c "CREATE ROLE agent WITH LOGIN SUPERUSER PASSWORD 'agent';" >/dev/null
    sudo -u postgres psql -c "CREATE DATABASE agent OWNER agent;" >/dev/null

    # Shut down temporary instance
    sudo -u postgres /usr/lib/postgresql/${PG_VERSION}/bin/pg_ctl -D "$PG_DATA" -m fast -w stop >/dev/null
fi

# 3. Start PostgreSQL in the background for the session
sudo -u postgres /usr/lib/postgresql/${PG_VERSION}/bin/pg_ctl -D "$PG_DATA" -w start >/dev/null

echo "✅ Environment Ready."
echo "   - Python & Postgres are running locally in this container."
# echo "   - Run 'claude' or 'copilot' to start the AI agents."
echo "   - Run 'copilot' to start the AI agent."

# Drop into the interactive bash shell
exec "$@"
