#!/bin/bash

DOCKERFILE=Dockerfile
PORTMAP_FILE=ports.map
IPADDRESS='0.0.0.0'
OS='alpine'

if [ ! -z $1 ];
then
    if [ "debian" = "${1}" ];
    then
        OS='debian'
    fi
fi


echo "# auto-generated Dockerfile" > $DOCKERFILE
echo "FROM ${OS}" >> $DOCKERFILE

echo "MAINTAINER foospidy" >> $DOCKERFILE

# install software
if [ "alpine" = "${OS}" ];
then
    echo "RUN apk update" >> $DOCKERFILE
    echo "RUN apk add wget unzip ca-certificates python py-pip py-setuptools python-dev musl-dev gcc" >> $DOCKERFILE
    echo "RUN update-ca-certificates" >> $DOCKERFILE
    echo "RUN pip install requests" >> $DOCKERFILE
    echo "RUN pip install twisted" >> $DOCKERFILE
    echo "RUN pip install pipreqs" >> $DOCKERFILE
else
    echo "RUN apt-get update" >> $DOCKERFILE
    echo "RUN apt-get install -y wget unzip python python-pip python-requests python-twisted" >> $DOCKERFILE
    echo "RUN apt-get clean" >> $DOCKERFILE
    echo "RUN pip install pipreqs" >> $DOCKERFILE
fi

# create user
if [ "alpine" = "${OS}" ];
then
    #echo "RUN adduser -G honey -S honey" >> $DOCKERFILE
    echo "RUN addgroup honey && adduser -s /bin/bash -D -G honey honey" >> $DOCKERFILE
else
    echo "RUN useradd -ms /bin/bash honey" >> $DOCKERFILE
fi

# setup HoneyPy
echo "RUN mkdir -p /opt" >> $DOCKERFILE
echo "RUN cd /opt && wget https://github.com/foospidy/HoneyPy/archive/master.zip" >> $DOCKERFILE
echo "RUN cd /opt && unzip master.zip" >> $DOCKERFILE
echo "RUN cd /opt && mv HoneyPy-master HoneyPy" >> $DOCKERFILE
echo "RUN cd /opt && rm master.zip" >> $DOCKERFILE
echo "RUN chmod +x /opt/HoneyPy/Honey.py" >> $DOCKERFILE
echo "COPY etc/honeypy.cfg /opt/HoneyPy/etc/" >> $DOCKERFILE
echo "COPY etc/services.cfg /opt/HoneyPy/etc/" >> $DOCKERFILE
echo "RUN pipreqs --force /opt/HoneyPy" >> $DOCKERFILE
echo "RUN chown -R honey:honey /opt/HoneyPy" >> $DOCKERFILE

# install clilib
echo "RUN cd /opt && wget https://github.com/foospidy/clilib/archive/master.zip" >> $DOCKERFILE
echo "RUN cd /opt && unzip master.zip" >> $DOCKERFILE
echo "RUN cd /opt && rm master.zip" >> $DOCKERFILE
echo "RUN cd /opt && mv clilib-master clilib" >> $DOCKERFILE
echo "RUN cd /opt/clilib && python setup.py bdist_egg" >> $DOCKERFILE
echo "RUN cd /opt/clilib && easy_install-2.7 -Z dist/clilib-0.0.1-py2.7.egg" >> $DOCKERFILE

# setup ipt-kit
echo "RUN cd /opt && wget https://github.com/foospidy/ipt-kit/archive/master.zip" >> $DOCKERFILE
echo "RUN cd /opt && unzip master.zip" >> $DOCKERFILE
echo "RUN cd /opt && rm master.zip" >> $DOCKERFILE
echo "RUN cd /opt && mv ipt-kit-master ipt-kit" >> $DOCKERFILE

# set run user
echo "USER honey" >> $DOCKERFILE
echo "WORKDIR /opt/HoneyPy" >> $DOCKERFILE

# get configured ports and generate expose list
TCP_LPORTS=(`cat etc/services.cfg | grep -E "low_port.*tcp" | sed -e 's/^.*://'`)
TCP_HPORTS=(`cat etc/services.cfg | grep -E "^\s?port.*tcp" | sed -e 's/^.*://'`)
UDP_LPORTS=(`cat etc/services.cfg | grep -E "low_port.*udp" | sed -e 's/^.*://'`)
UDP_HPORTS=(`cat etc/services.cfg | grep -E "^\s?port.*udp" | sed -e 's/^.*://'`)

if [ -f $PORTMAP_FILE ]
then
    echo "" > $PORTMAP_FILE
fi

index=0

while [ "x${TCP_LPORTS[index]}" != "x" ]
do
    echo "EXPOSE ${TCP_LPORTS[$index]}/tcp" >> $DOCKERFILE
    echo -n "-p ${IPADDRESS}:${TCP_LPORTS[$index]}:${TCP_HPORTS[$index]}/tcp " >> $PORTMAP_FILE
    index=$(( index + 1 ))
done

index=0

while [ "x${UDP_LPORTS[index]}" != "x" ]
do
    echo "EXPOSE ${UDP_LPORTS[$index]}/udp" >> $DOCKERFILE
    echo -n "-p ${IPADDRESS}:${UDP_LPORTS[$index]}:${UDP_HPORTS[$index]}/udp " >> $PORTMAP_FILE
    index=$(( index + 1 ))
done
