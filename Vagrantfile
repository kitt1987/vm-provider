# -*- mode: ruby -*-
# vi: set ft=ruby :

CLUSTER_NAME = "kube-route"
NUM_MASTERS = 1
NUM_NODES = 2

Vagrant.configure("2") do |config|
  BASE_BOX = "ubuntu1604-docker"
  VMGROUP = "/" + CLUSTER_NAME
  DOMAIN_SUFFIX = "." + CLUSTER_NAME + ".env.lab.io"

  config.ssh.username = "root"
  config.ssh.private_key_path = "/Volumes/Warehouse/vagrant/.ssh/id_rsa"

  (1..NUM_MASTERS).each do |i|
    config.vm.define "m#{i}" do |master|
      master.vm.box = BASE_BOX
      master.vm.hostname = "m#{i}" + DOMAIN_SUFFIX

      r = Vagrant::Util::Subprocess.execute(
        'ssh',
        'root@10.38.0.2',
        '/usr/local/bin/ssh-proxy.sh',
        master.vm.hostname,
        :notify => [:stdout, :stderr],)

      raise r.stderr if r.exit_code != 0
      addr = r.stdout.split(/\s+/)
      raise addr if addr.length != 2
      mac = addr[0]
      ip = addr[1]

      master.vm.network :forwarded_port, guest: 22, host: 2222, id: "ssh", disabled: true
      master.vm.network :private_network, :name => 'vboxnet0', :adapter => 1, ip: "10.38.254.254", :mac => mac, auto_config: false
      
      master.ssh.port = 22
      master.ssh.host = ip

      master.vm.provider :virtualbox do |vbox|
        vbox.name = "m#{i}"
        vbox.customize ["modifyvm", :id, "--groups", VMGROUP]
      end
    end
  end

  (1..NUM_NODES).each do |i|
    config.vm.define "n#{i}" do |node|
      node.vm.box = BASE_BOX
      node.vm.hostname = "n#{i}" + DOMAIN_SUFFIX

      r = Vagrant::Util::Subprocess.execute(
        'ssh',
        'root@10.38.0.2',
        '/usr/local/bin/ssh-proxy.sh',
        node.vm.hostname,
        :notify => [:stdout, :stderr],)

      raise r.stderr if r.exit_code != 0
      addr = r.stdout.split(/\s+/)
      raise addr if addr.length != 2
      mac = addr[0]
      ip = addr[1]

      node.vm.network :forwarded_port, guest: 22, host: 2222, id: "ssh", disabled: true
      node.vm.network :private_network, :name => 'vboxnet0', :adapter => 1, ip: "10.38.254.254", :mac => mac, auto_config: false

      node.ssh.port = 22
      node.ssh.host = ip

      node.vm.provider :virtualbox do |vbox|
        vbox.name = "n#{i}"
        vbox.customize ["modifyvm", :id, "--groups", VMGROUP]
      end
    end
  end
end
