#!/bin/bash

DOCKERFILE=Dockerfile
PORTMAP_FILE=ports.map
IPADDRESS='0.0.0.0'
OS='alpine'

if [ ! -z $1 ]; then
    if [ "debian" = "${1}" ]; then
        OS='debian'
    fi
fi


cat << EOT > $DOCKERFILE
# auto-generated Dockerfile
FROM ${OS}
MAINTAINER foospidy
EOT

# install software
if [ "alpine" = "${OS}" ]; then
    cat << EOT >> $DOCKERFILE
RUN apk update && \\
    apk add wget unzip ca-certificates python py-pip py-setuptools python-dev musl-dev gcc && \\
    pip install requests && \\
    pip install twisted && \\
    pip install pipreqs && \\
    addgroup honey && \\
    adduser -s /bin/bash -D -G honey honey && \\
EOT
else
    cat << EOT >> $DOCKERFILE
RUN apt-get update && \\
    apt-get install -y wget unzip python python-pip python-requests python-twisted && \\
    apt-get clean && \\
    pip install pipreqs && \\
    useradd -ms /bin/bash honey && \\
EOT
fi

cat << EOT >> $DOCKERFILE
    mkdir -p /opt && \\
    cd /opt && wget https://github.com/foospidy/HoneyPy/archive/master.zip && \\
        unzip master.zip && \\
        mv HoneyPy-master HoneyPy && \\
        rm master.zip && \\
    chmod +x /opt/HoneyPy/Honey.py && \\
    pipreqs --force /opt/HoneyPy && \\
    chown -R honey:honey /opt/HoneyPy && \\
    cd /opt && wget https://github.com/foospidy/clilib/archive/master.zip && \\
        unzip master.zip && \\
        rm master.zip && \\
        mv clilib-master clilib && \\
    cd /opt/clilib && python setup.py bdist_egg && \\
        easy_install-2.7 -Z dist/clilib-0.0.1-py2.7.egg && \\
    cd /opt && wget https://github.com/foospidy/ipt-kit/archive/master.zip && \\
        unzip master.zip && \\
        rm master.zip && \\
        mv ipt-kit-master ipt-kit

COPY etc/honeypy.cfg /opt/HoneyPy/etc/
COPY etc/services.cfg /opt/HoneyPy/etc/

USER honey

WORKDIR /opt/HoneyPy
EOT

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
