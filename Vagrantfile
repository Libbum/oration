# -*- mode: ruby -*-
# vi: set ft=ruby :

# You'll need the vagrant-triggers plugin for this file to function correctly:
# $ vagrant plugin install vagrant-triggers

Vagrant.configure("2") do |config|
  config.vm.box = "debian/jessie64"

  config.vm.network :forwarded_port, guest: 80, host: 8600

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "staging/staging.yml"
    ansible.limit = "all"
    ansible.verbose = "v"
  end

  config.vm.provision "ansible", run: "always" do |ansible|
    ansible.playbook = "staging/services.yml"
    ansible.limit = "all"
    ansible.verbose = "v"
  end

  config.vm.synced_folder "public", "/vagrant/public_html", create: true, type: "rsync"
  config.vm.synced_folder "staging/deploy", "/vagrant/app", create: true, type: "rsync"
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.post_up_message = "The Oration staging service is now available at http://localhost:8600"

  config.trigger.before [:up, :resume, :reload] do
    info "Building files for staging environment"
    run "ansible-playbook -i 'localhost,' -c local staging/prepare.yml"
  end
end
