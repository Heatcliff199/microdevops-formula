docker-ce:
  version: latest
  daemon_json: |
    { "iptables": false, "default-address-pools": [ {"base": "172.16.0.0/12", "size": 24} ] }
