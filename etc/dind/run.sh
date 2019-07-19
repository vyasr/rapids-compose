#!/bin/bash -e

cd "$COMPOSE_HOME"

args="";
file=${1:-""};

if [[ ! -z "${file// }" ]]; then shift; fi;

# Separate the `docker-compose run` args from the dockerfile and service names

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -T) args="${args:+$args }$1";;                     # Disable pseudo-tty allocation. By default `docker-compose run` allocates a TTY.
        --rm) args="${args:+$args }$1";;                   # Remove container after run. Ignored in detached mode.
        -d|--detach) args="${args:+$args }$1";;            # Detached mode: Run container in the background, print new container name.
        --no-deps) args="${args:+$args }$1";;              # Don't start linked services.
        --service-ports) args="${args:+$args }$1";;        # Run command with the service's ports enabled and mapped to the host.
        --use-aliases) args="${args:+$args }$1";;          # Use the service's network aliases in the network(s) the container connects to.
        --name) args="${args:+$args }$1 $2"; shift;;       # Assign a name to the container
        -e) args="${args:+$args }$1 $2"; shift;;           # Set an environment variable (can be used multiple times)
        --entrypoint) args="${args:+$args }$1 $2"; shift;; # Override the entrypoint of the image.
        -l|--label) args="${args:+$args }$1 $2"; shift;;   # Add or override a label (can be used multiple times)
        -p|--publish) args="${args:+$args }$1 $2"; shift;; # Publish a container's port(s) to the host
        -v|--volume) args="${args:+$args }$1 $2"; shift;;  # Bind mount a volume (default [])
        -u|--user) args="${args:+$args }$1 $2"; shift;;    # Run as specified username or uid
        -w|--workdir) args="${args:+$args }$1 $2"; shift;; # Working directory inside the container
        *) break;;
    esac; shift;
done

file="$file";
args="$args";
services=$*;

docker-compose -f $file run $args $services | tee /dev/null &
pid=$!

print_svc_ip() {
    service="compose_$1"
    query=".[].Containers | to_entries | .[].value"
    query="$query | select(.Name | startswith(\"$service\"))"
    query="$query | .IPv4Address | \"$service ip: \(.[0:-3])\""
    docker network inspect compose_default 2>/dev/null | jq -r -c "$(echo "$query")"
}

service=${services[0]}
if [ "$service" != "" ]; then
    result=""
    until [ "$result" != "" ]; do
        sleep 0.1;
        result="$(print_svc_ip $service)"
    done;
    echo -e -n "$result\n\r"
fi

wait $pid
exit $?
