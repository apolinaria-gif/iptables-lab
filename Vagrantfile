
# -*- mode: ruby -*-
# vi: set ft=ruby :

MACHINES = {
  :inetRouter => {
    :box_name => "generic/ubuntu2204",
    :vm_name => "inetRouter",
    :net => [
      ["192.168.255.1", 2, "255.255.255.252", "router-net"]
    ]
  },

  :centralRouter => {
    :box_name => "generic/ubuntu2204",
    :vm_name => "centralRouter",
    :net => [
      ["192.168.255.2", 2, "255.255.255.252", "router-net"],
      ["192.168.0.1", 3, "255.255.255.240", "dir-net"]
    ]
  },

  :inetRouter2 => {
    :box_name => "generic/ubuntu2204",
    :vm_name => "inetRouter2",
    :net => [
      ["192.168.0.3", 3, "255.255.255.240", "dir-net"],
      ["192.168.50.13", 8, "255.255.255.0", nil]
    ]
  },

  :centralServer => {
    :box_name => "generic/ubuntu2204",
    :vm_name => "centralServer",
    :net => [
      ["192.168.0.2", 2, "255.255.255.240", "dir-net"]
    ]
  }
}

Vagrant.configure("2") do |config|

  config.vm.synced_folder ".", "/vagrant"

  MACHINES.each do |boxname, boxconfig|

    config.vm.define boxname do |box|

      box.vm.box = boxconfig[:box_name]
      box.vm.hostname = boxconfig[:vm_name]

      box.vm.provider "virtualbox" do |v|
        v.memory = 1024
        v.cpus = 1
      end

      boxconfig[:net].each do |ipconf|
        if ipconf[3]
          box.vm.network(
            "private_network",
            ip: ipconf[0],
            adapter: ipconf[1],
            netmask: ipconf[2],
            virtualbox__intnet: ipconf[3]
          )
        else
          box.vm.network(
            "private_network",
            ip: ipconf[0],
            adapter: ipconf[1],
            netmask: ipconf[2]
          )
        end
      end

      # Windows localhost:8080 -> inetRouter2:8080
      if boxname == :inetRouter2
        box.vm.network(
          "forwarded_port",
          guest: 8080,
          host: 8080,
          host_ip: "127.0.0.1",
          protocol: "tcp",
          auto_correct: true
        )
      end

      # DNS и APT на каждой ВМ.
      box.vm.provision "shell",
        name: "Configure DNS and APT",
        run: "always",
        inline: <<-SHELL
          set -e

          rm -f /etc/resolv.conf

          cat > /etc/resolv.conf <<'EOF'
nameserver 10.0.2.3
options timeout:2 attempts:3
EOF

          chmod 644 /etc/resolv.conf

          cat > /etc/apt/apt.conf.d/99force-ipv4 <<'EOF'
Acquire::ForceIPv4 "true";
EOF

          echo "DNS and APT configured:"
          cat /etc/resolv.conf
        SHELL

      if boxname == :centralServer

        # Копирование SSH-ключей остальных ВМ.
        box.vm.provision "shell", inline: <<-SHELL
          set -e

          install -d -m 700 -o vagrant -g vagrant \
            /home/vagrant/.ssh/ansible

          for machine in inetRouter centralRouter inetRouter2; do
            src="/vagrant/.vagrant/machines/${machine}/virtualbox/private_key"

            if [ ! -f "$src" ]; then
              echo "SSH key not found: $src"
              exit 1
            fi

            install -m 600 -o vagrant -g vagrant \
              "$src" \
              "/home/vagrant/.ssh/ansible/${machine}_key"
          done
        SHELL

        # Ansible запускается на centralServer.
        box.vm.provision "ansible_local" do |ansible|
          ansible.playbook = "ansible/site.yml"
          ansible.inventory_path = "/vagrant/ansible/inventory.ini"
          ansible.config_file = "/vagrant/ansible/ansible.cfg"
          ansible.provisioning_path = "/vagrant"
          ansible.limit = "all"
          ansible.install = true
        end

      end
    end
  end
end
