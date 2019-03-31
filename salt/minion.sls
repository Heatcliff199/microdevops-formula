{% if pillar['salt'] is defined and pillar['salt'] is not none and pillar['salt']['minion'] is defined and pillar['salt']['minion'] is not none %}

  {%- for host in pillar['salt']['minion']['hosts'] %}
salt_master_hosts_{{ loop.index }}:
  host.present:
    - clean: True
    - ip: {{ host['ip'] }}
    - names:
        - {{ host['name'] }}
  {%- endfor %}

  {%- if grains['os'] in ['Windows'] %}
    {%- if pillar['salt']['minion']['version'] == 2019.2 %}
      {%- set minion_exe = 'Salt-Minion-2019.2.0-Py3-AMD64-Setup.exe' -%}
    {%- endif %}

    {%- if pillar['salt']['minion']['version']|string != grains['saltversioninfo'][0]|string + '.' + grains['saltversioninfo'][1]|string %}
minion_installer_exe:
  file.managed:
    - name: 'C:\Windows\{{ minion_exe }}'
    - source: salt://salt/{{ minion_exe }}

minion_install_silent_cmd:
  cmd.run:
    - name: 'START /B C:\Windows\{{ minion_exe }} /S /master={{ pillar['salt']['minion']['config']['master']|join(',') }} /minion-name={{ grains['fqdn'] }} /start-minion=1'
    {%- endif %}

salt_minion_config:
  file.serialize:
    - name: 'C:\salt\conf\minion'
    - show_changes: True
    - create: True
    - merge_if_exists: False
    - formatter: yaml
    - dataset: {{ pillar['salt']['minion']['config'] }}

salt_minion_config_restart:
  module.run:
    - name: service.restart
    - m_name: salt-minion
    - onchanges:
        - file: 'C:\salt\conf\minion'

  {%- elif grains['os'] in ['Ubuntu', 'Debian', 'Centos'] %}
    {%- elif grains['os'] in ['Ubuntu', 'Debian'] %}

salt_minion_repo:
  pkgrepo.managed:
    - humanname: SaltStack Repository
    - name: deb http://repo.saltstack.com/apt/{{ grains['os']|lower }}/{{ grains['osrelease'] }}/amd64/{{ pillar['salt']['minion']['version'] }} {{ grains['oscodename'] }} main
    - file: /etc/apt/sources.list.d/saltstack.list
    - key_url: https://repo.saltstack.com/apt/{{ grains['os']|lower }}/{{ grains['osrelease'] }}/amd64/{{ pillar['salt']['minion']['version'] }}/SALTSTACK-GPG-KEY.pub
    - clean_file: True
    - refresh: True

      {%- if pillar['salt']['minion']['version']|string != grains['saltversioninfo'][0]|string + '.' + grains['saltversioninfo'][1]|string %}
salt_minion_update_restart:
  cmd.run:
    - name: |
        exec 0>&- # close stdin
        exec 1>&- # close stdout
        exec 2>&- # close stderr
        nohup /bin/sh -c 'apt-get update; apt-get -qy -o 'DPkg::Options::=--force-confold' -o 'DPkg::Options::=--force-confdef' install salt-minion={{ pillar['salt']['minion']['version']|string }}* && salt-call --local service.restart salt-minion' &
      {%- endif %}

    {%- endif %}

salt_minion_config:
  file.serialize:
    - name: /etc/salt/minion
    - user: root
    - group: root
    - mode: 644
    - show_changes: True
    - create: True
    - merge_if_exists: False
    - formatter: yaml
    - dataset: {{ pillar['salt']['minion']['config'] }}

salt_minion_config_restart:
  cmd.run:
    - name: |
        exec 0>&- # close stdin
        exec 1>&- # close stdout
        exec 2>&- # close stderr
        nohup /bin/sh -c 'salt-call --local service.restart salt-minion' &
    - onchanges:
        - file: /etc/salt/minion

  {%- endif %}

{% endif %}