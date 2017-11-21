# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "debian/jessie64"

  config.vm.network :forwarded_port, guest: 80, host: 8600

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "ansible/staging.yml"
    ansible.galaxy_role_file = "ansible/requirements.yml"
    ansible.limit = "all"
    ansible.verbose = "v"
  end

  config.vm.post_up_message = "The Oration test service is now available at http://localhost:8600"
end
