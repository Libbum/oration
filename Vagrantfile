# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "debian/jessie64"

  config.vm.hostname = 'oration.local'
  config.vm.network "private_network", type: "dhcp"

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "ansible/staging.yml"
    ansible.galaxy_role_file = "ansible/requirements.yml"
    ansible.limit = "all"
    ansible.verbose = "v"
  end
end
