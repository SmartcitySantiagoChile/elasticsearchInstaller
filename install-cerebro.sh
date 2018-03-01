#!/bin/bash

# Download cerebro
if [ ! -f cerebro-0.7.2.tgz ]; then
wget https://github.com/lmenezes/cerebro/releases/download/v0.7.2/cerebro-0.7.2.tgz
fi

# Unpack cerebro
tar -zxf cerebro-0.7.2.tgz

echo "Installing cerebro..."

# Check if cerebro user exists. If it doesn't, create it.
if id "cerebro" >/dev/null 2>&1; then
        :
else
        echo "Creating cerebro user..."
	sudo useradd cerebro
fi

# Copy cerebro folder /to usr/share
sudo cp -r cerebro-0.7.2 /usr/share/

# Copy cerebro.service to usr/lib
sudo cp cerebro.service /etc/systemd/system

# Enable service
sudo systemctl enable cerebro.service

# Set parameters
echo -n "Enter IP address: "
read CIP
echo -n "Enter port: "
read CPORT
sudo sed -i 's|^ExecStart = /usr/share/cerebro-0.7.2/bin/cerebro -Dpidfile.path=/dev/null -Dhttp.port=.* -Dhttp.address=.*$|ExecStart = /usr/share/cerebro-0.7.2/bin/cerebro -Dpidfile.path=/dev/null -Dhttp.port='"$CPORT"' -Dhttp.address='"$CIP"'|' /etc/systemd/system/cerebro.service

# Reload DAEMON and start service
sudo systemctl daemon-reload
sudo systemctl start cerebro.service

echo "Done. Cerebro is now running on http://"$CIP":"$CPORT"."

# Check status
#systemctl status cerebro.service
