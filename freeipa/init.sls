{%- if pillar["freeipa"] is defined %}
hosts_file:
  host.only:
    - name: 127.0.1.1
    - hostnames: []

freeipa_data_dir:
  file.directory:
    - names:
      - /opt/freeipa/{{ pillar["freeipa"]["hostname"] }}/data
    - mode: 755
    - makedirs: True

  {%- if 'acme_account' in pillar["freeipa"] %}
verify and issue le certificate:
  cmd.run:
    - shell: /bin/bash
    - name: "/opt/acme/home/{{ pillar["freeipa"]["acme_account"] }}/verify_and_issue.sh freeipa {{ pillar["freeipa"]["hostname"] }}"

script_for_cert_check_and_install:
  file.managed:
    - name: /opt/freeipa/{{ pillar['freeipa']['hostname'] }}/certificate_check_and_install.sh
    - contents: |
        #!/bin/bash

        fp_of_cert_in_file="$(echo | openssl s_client -connect {{ pillar['freeipa']['hostname'] }}:443 |& openssl x509 -fingerprint -noout -sha256)"
        fp_of_cert_installed="$(openssl x509 -noout -in /opt/acme/cert/freeipa_{{ pillar['freeipa']['hostname'] }}_cert.cer -fingerprint -sha256)"

        if [[ "${fp_of_cert_in_file}" == "${fp_of_cert_installed}" ]]; then
          exit 0;
        else
          docker exec freeipa-{{ pillar["freeipa"]["hostname"] }} bash -c "echo {{ pillar['freeipa']['ds_password'] }} | ipa-server-certinstall -w -d /acme/freeipa_{{ pillar['freeipa']['hostname'] }}_key.key /acme/freeipa_{{ pillar['freeipa']['hostname'] }}_cert.cer --pin=''"
          docker exec freeipa-{{ pillar["freeipa"]["hostname"] }} bash -c "ipactl restart"
        fi
    - mode: 700

create cron for check and install certs:
  cron.present:
    - name: /opt/freeipa/{{ pillar['freeipa']['hostname'] }}/certificate_check_and_install.sh
    - identifier: checking freeipa certificates and reload freeipa
    - user: root
    - minute: 10
    - hour: 1
  {%- endif %}

  {%- if 'ca_fix' in pillar["freeipa"] and pillar["freeipa"]["ca_fix"] == True %}
freeipa_{{ pillar["freeipa"]["hostname"] }}_ca-fixed.cer:
  file.managed:
    - name: "/opt/acme/cert/freeipa_{{ pillar["freeipa"]["hostname"] }}_ca-fixed.cer"
    - makedirs: True
    - contents: |
        -----BEGIN CERTIFICATE-----
        MIIFFjCCAv6gAwIBAgIRAJErCErPDBinU/bWLiWnX1owDQYJKoZIhvcNAQELBQAw
        TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
        cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMjAwOTA0MDAwMDAw
        WhcNMjUwOTE1MTYwMDAwWjAyMQswCQYDVQQGEwJVUzEWMBQGA1UEChMNTGV0J3Mg
        RW5jcnlwdDELMAkGA1UEAxMCUjMwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
        AoIBAQC7AhUozPaglNMPEuyNVZLD+ILxmaZ6QoinXSaqtSu5xUyxr45r+XXIo9cP
        R5QUVTVXjJ6oojkZ9YI8QqlObvU7wy7bjcCwXPNZOOftz2nwWgsbvsCUJCWH+jdx
        sxPnHKzhm+/b5DtFUkWWqcFTzjTIUu61ru2P3mBw4qVUq7ZtDpelQDRrK9O8Zutm
        NHz6a4uPVymZ+DAXXbpyb/uBxa3Shlg9F8fnCbvxK/eG3MHacV3URuPMrSXBiLxg
        Z3Vms/EY96Jc5lP/Ooi2R6X/ExjqmAl3P51T+c8B5fWmcBcUr2Ok/5mzk53cU6cG
        /kiFHaFpriV1uxPMUgP17VGhi9sVAgMBAAGjggEIMIIBBDAOBgNVHQ8BAf8EBAMC
        AYYwHQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMBMBIGA1UdEwEB/wQIMAYB
        Af8CAQAwHQYDVR0OBBYEFBQusxe3WFbLrlAJQOYfr52LFMLGMB8GA1UdIwQYMBaA
        FHm0WeZ7tuXkAXOACIjIGlj26ZtuMDIGCCsGAQUFBwEBBCYwJDAiBggrBgEFBQcw
        AoYWaHR0cDovL3gxLmkubGVuY3Iub3JnLzAnBgNVHR8EIDAeMBygGqAYhhZodHRw
        Oi8veDEuYy5sZW5jci5vcmcvMCIGA1UdIAQbMBkwCAYGZ4EMAQIBMA0GCysGAQQB
        gt8TAQEBMA0GCSqGSIb3DQEBCwUAA4ICAQCFyk5HPqP3hUSFvNVneLKYY611TR6W
        PTNlclQtgaDqw+34IL9fzLdwALduO/ZelN7kIJ+m74uyA+eitRY8kc607TkC53wl
        ikfmZW4/RvTZ8M6UK+5UzhK8jCdLuMGYL6KvzXGRSgi3yLgjewQtCPkIVz6D2QQz
        CkcheAmCJ8MqyJu5zlzyZMjAvnnAT45tRAxekrsu94sQ4egdRCnbWSDtY7kh+BIm
        lJNXoB1lBMEKIq4QDUOXoRgffuDghje1WrG9ML+Hbisq/yFOGwXD9RiX8F6sw6W4
        avAuvDszue5L3sz85K+EC4Y/wFVDNvZo4TYXao6Z0f+lQKc0t8DQYzk1OXVu8rp2
        yJMC6alLbBfODALZvYH7n7do1AZls4I9d1P4jnkDrQoxB3UqQ9hVl3LEKQ73xF1O
        yK5GhDDX8oVfGKF5u+decIsH4YaTw7mP3GFxJSqv3+0lUFJoi5Lc5da149p90Ids
        hCExroL1+7mryIkXPeFM5TgO9r0rvZaBFOvV2z0gp35Z0+L4WPlbuEjN/lxPFin+
        HlUjr8gRsI3qfJOQFy/9rKIJR0Y/8Omwt/8oTWgy1mdeHmmjk7j1nYsvC9JSQ6Zv
        MldlTTKB3zhThV1+XWYp6rjd5JW1zbVWEkLNxE7GJThEUG3szgBVGP7pSWTUTsqX
        nLRbwHOoq7hHwg==
        -----END CERTIFICATE-----
        -----BEGIN CERTIFICATE-----
        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
        -----END CERTIFICATE-----

create fixed fullchain.cer 1:
  cmd.run:
    - shell: /bin/bash
    - name: "cat /opt/acme/cert/freeipa_{{ pillar["freeipa"]["hostname"] }}_cert.cer > /opt/acme/cert/freeipa_{{ pillar["freeipa"]["hostname"] }}_fullchain-fixed.cer"
create fixed fullchain.cer 2:
  cmd.run:
    - shell: /bin/bash
    - name: "cat /opt/acme/cert/freeipa_{{ pillar["freeipa"]["hostname"] }}_ca-fixed.cer >> /opt/acme/cert/freeipa_{{ pillar["freeipa"]["hostname"] }}_fullchain-fixed.cer"

  {%- endif %}

  {%- if 'ipa_server_install_options' in pillar["freeipa"] %}
ipa_server_install_options:
  file.managed:
    - name: /opt/freeipa/{{ pillar["freeipa"]["hostname"] }}/data/ipa-server-install-options
    - contents_pillar: freeipa:ipa_server_install_options
  {%- endif %}

freeipa_image:
  cmd.run:
    - name: docker pull {{ pillar["freeipa"]["image"] }}

freeipa_container:
  docker_container.running:
    - name: freeipa-{{ pillar["freeipa"]["hostname"] }}
    - user: root
    - image: {{ pillar["freeipa"]["image"] }}
    - detach: True
    - restart_policy: unless-stopped
    - tmpfs:
      - /run: rw,noexec,nosuid,size=65536k
      - /tmp: rw,noexec,nosuid,size=524288k
    - cap_add: SYS_TIME
    {%- if 'extra_hosts' in pillar["freeipa"] %}
    - extra_hosts:
      {%- for extra_host in pillar["freeipa"]["extra_hosts"] %}
        - {{ extra_host }}
      {%- endfor %}
    {%- endif %}
    {%- if 'network_mode' in pillar["freeipa"] and 'host' in pillar["freeipa"]["network_mode"] %}
    - network_mode: host
    {%- else %}
    - hostname: {{ pillar["freeipa"]["hostname"] }}
      {%- if 'sysctls' in pillar["freeipa"] %}
    - sysctls:
        {%- for sysctl in pillar["freeipa"]["sysctls"] %}
        - {{ sysctl }}
        {%- endfor %}
      {%- endif %}
    - publish:
        - {{ pillar["freeipa"]["ip"] }}:53:53
        - {{ pillar["freeipa"]["ip"] }}:53:53/udp
        - {{ pillar["freeipa"]["ip"] }}:80:80
        - {{ pillar["freeipa"]["ip"] }}:88:88
        - {{ pillar["freeipa"]["ip"] }}:88:88/udp
        - {{ pillar["freeipa"]["ip"] }}:123:123/udp
        - {{ pillar["freeipa"]["ip"] }}:389:389
        - {{ pillar["freeipa"]["ip"] }}:443:443
        - {{ pillar["freeipa"]["ip"] }}:464:464
        - {{ pillar["freeipa"]["ip"] }}:464:464/udp
        - {{ pillar["freeipa"]["ip"] }}:636:636
    {%- endif %}
    {%- if 'command' in pillar["freeipa"] %}
      {%- if 'ca_fix' in pillar["freeipa"] and pillar["freeipa"]["ca_fix"] == True and 'ca_less' in pillar["freeipa"] and pillar["freeipa"]["ca_less"] == True %}
    - command: {{ pillar["freeipa"]["command"] }} --http-cert-file /acme/freeipa_{{ pillar["freeipa"]["hostname"] }}_fullchain-fixed.cer --http-cert-file /acme/freeipa_{{ pillar["freeipa"]["hostname"] }}_key.key  --http-pin '' --dirsrv-cert-file /acme/freeipa_{{ pillar["freeipa"]["hostname"] }}_fullchain-fixed.cer --dirsrv-cert-file /acme/freeipa_{{ pillar["freeipa"]["hostname"] }}_key.key  --dirsrv-pin '' --no-pkinit 
      {%- elif  'ca_less' in pillar["freeipa"] and pillar["freeipa"]["ca_less"] == True %}
    - command: {{ pillar["freeipa"]["command"] }} --http-cert-file /acme/freeipa_{{ pillar["freeipa"]["hostname"] }}_fullchain-fixed.cer --http-cert-file /acme/freeipa_{{ pillar["freeipa"]["hostname"] }}_key.key --http-pin '' --dirsrv-cert-file /acme/freeipa_{{ pillar["freeipa"]["hostname"] }}_fullchain.cer --dirsrv-cert-file /acme/freeipa_{{ pillar["freeipa"]["hostname"] }}_key.key  --dirsrv-pin '' --no-pkinit
      {%- else %}
    - command: {{ pillar["freeipa"]["command"] }}
      {%- endif %}
    {%- endif %}
    {%- if 'dns' in pillar["freeipa"] %}
    - dns:
      {%- for address in pillar["freeipa"]["dns"] %}
        - {{ address }}
      {%- endfor %}
    {%- endif %}
    - binds:
        - /opt/freeipa/{{ pillar["freeipa"]["hostname"] }}/data:/data:rw
        - /sys/fs/cgroup:/sys/fs/cgroup:ro
        - /opt/acme/cert:/acme:ro
  {%- if 'env_var' in pillar["freeipa"] %}
    - environment:
    {%- for var_key, var_val in pillar["freeipa"]["env_vars"].items() %}
        - {{ var_key }}: {{ var_val }}
    {%- endfor %}
  {%- endif %}
{%- endif %}
