#!/bin/bash

CONFPATH=/etc/apt/apt.conf.d/01proxy

if [[ -n "$APT_HTTP_PROXY" ]]; then
    cat > $CONFPATH <<-EOL
Acquire::HTTP::Proxy "${APT_HTTP_PROXY}";
Acquire::HTTPS::Proxy "false";
EOL
    echo "Using host's apt proxy: APT_HTTP_PROXY=$APT_HTTP_PROXY" >&2
else
    rm -f "$CONFPATH"
    echo "Deleted proxy configuration since APT_HTTP_PROXY is unset." >&2
fi
