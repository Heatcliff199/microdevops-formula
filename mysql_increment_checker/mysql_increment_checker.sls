{% if pillar['mysql_increment_checker'] is defined and pillar['mysql_increment_checker'] is not none and pillar['mysql_increment_checker']['enabled'] is defined and pillar['mysql_increment_checker']['enabled'] is not none and pillar['mysql_increment_checker']['enabled'] %}

  {%- if salt['file.directory_exists']('/opt/sysadmws/mysql_increment_checker') %}
    {%- if pillar['mysql_increment_checker']['config'] is defined and pillar['mysql_increment_checker']['config'] is not none %}
swsu_v1_mysql_increment_checker_config_managed:
  file.serialize:
    - name: '/opt/sysadmws/mysql_increment_checker/mysql_increment_checker.yaml'
    - mode: 0644
    - user: root
    - group: root
    - dataset_pillar: mysql_increment_checker:config
    - serializer: yaml
    {%- else %}
swsu_v1_mysql_increment_checker_config_managed:
  file.absent:
    - name: '/opt/sysadmws/mysql_increment_checker/mysql_increment_checker.yaml'
    {%- endif %}

swsu_v1_mysql_increment_checker_cron_managed:
  cron.present:
    - name: '/opt/sysadmws/mysql_increment_checker/mysql_increment_checker.py'
    - identifier: mysql_increment_checker
    - user: root
    - minute: '*/30'
  {%- endif %}

{% else %}
mysql_increment_checker_nothing_done_info:
  test.configurable_test_state:
    - name: nothing_done
    - changes: False
    - result: True
    - comment: |
        INFO: This state was not configured for a minion of this type, so nothing has been done. But it is OK.
{% endif %}
