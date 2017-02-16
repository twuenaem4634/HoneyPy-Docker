#!/bin/bash

DOCKERFILE=Dockerfile
PORTMAP_FILE=ports.map
IPADDRESS='0.0.0.0'
OS=${OS:-alpine}

cat << _MARKER > $DOCKERFILE
# auto-generated Dockerfile
FROM ${OS}
MAINTAINER foospidy
_MARKER

case ${OS} in
    alpine)
    cat << _MARKER >> $DOCKERFILE
RUN apk update && \\
    apk add ca-certificates python py-pip py-setuptools python-dev musl-dev gcc git && \\
    pip install --upgrade pip && \\
    pip install requests && \\
    pip install twisted && \\
    pip install pipreqs && \\
    addgroup honey && \\
    adduser -s /bin/bash -D -G honey honey && \\
_MARKER
    ;;
    debian)
    cat << _MARKER >> $DOCKERFILE
RUN apt-get update && \\
    apt-get install -y python python-pip python-dev git && \\
    pip install --upgrade pip && \\
    apt-get clean && \\
    pip install pipreqs && \\
    useradd -ms /bin/bash honey && \\
_MARKER
    ;;
    *)
        echo "FATAL: Unsupported OS: ${OS}"
        exit 1
    ;;
esac

cat << _MARKER >> $DOCKERFILE
    mkdir -p /opt && \\
    cd /opt && git clone https://github.com/foospidy/HoneyPy.git && \\
        git clone https://github.com/foospidy/clilib.git && \\
    python /opt/clilib/setup.py install && \\
    pip install -r /opt/HoneyPy/requirements.txt && \\
    pip install -U dnslib && \\
    chmod +x /opt/HoneyPy/Honey.py && \\
    chown -R honey:honey /opt/HoneyPy

COPY etc/honeypy.cfg /opt/HoneyPy/etc/
COPY etc/services.cfg /opt/HoneyPy/etc/

USER honey

WORKDIR /opt/HoneyPy

_MARKER

# get configured ports and generate expose list
TCP_LPORTS=(`cat etc/services.cfg | grep -E "low_port.*tcp" | sed -e 's/^.*://'`)
TCP_HPORTS=(`cat etc/services.cfg | grep -E "^\s?port.*tcp" | sed -e 's/^.*://'`)
UDP_LPORTS=(`cat etc/services.cfg | grep -E "low_port.*udp" | sed -e 's/^.*://'`)
UDP_HPORTS=(`cat etc/services.cfg | grep -E "^\s?port.*udp" | sed -e 's/^.*://'`)

echo "" > $PORTMAP_FILE

index=0

while [ "x${TCP_LPORTS[index]}" != "x" ]; do
    echo "EXPOSE ${TCP_LPORTS[$index]}/tcp" >> $DOCKERFILE
    echo -n "-p ${IPADDRESS}:${TCP_LPORTS[$index]}:${TCP_HPORTS[$index]}/tcp " >> $PORTMAP_FILE
    index=$(( index + 1 ))
done

index=0

while [ "x${UDP_LPORTS[index]}" != "x" ]; do
    echo "EXPOSE ${UDP_LPORTS[$index]}/udp" >> $DOCKERFILE
    echo -n "-p ${IPADDRESS}:${UDP_LPORTS[$index]}:${UDP_HPORTS[$index]}/udp " >> $PORTMAP_FILE
    index=$(( index + 1 ))
done
