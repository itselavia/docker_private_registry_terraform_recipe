sudo apt-get update
curl -fsSL https://get.docker.com/ | sh
sudo usermod -aG docker ubuntu
sudo touch /etc/docker/daemon.json
sudo echo {\"storage-driver\": \"overlay2\", \"insecure-registries\":[\"$1:5000\"]  } >> /etc/docker/daemon.json
sudo systemctl start docker
sudo chmod 600 /tmp/docker_ssh_key

ssh -i /tmp/docker_ssh_key -o StrictHostKeyChecking=no ubuntu@$1 <<EndOfCommands

	sudo apt-get update
	curl -fsSL https://get.docker.com/ | sh
	sudo usermod -aG docker ubuntu
	sudo touch /etc/docker/daemon.json
	sudo bash -c 'echo {\"storage-driver\": \"overlay2\" } >> /etc/docker/daemon.json'
	sudo systemctl start docker
	sudo docker run -d -p 5000:5000 --restart=always --name registry registry:2

EndOfCommands
