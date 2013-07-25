include_recipe 'clearstorydata-amplab::tachyon-install'

if node['csd-tachyon']['enabled']
  tachyon_user = node['csd-tachyon']['user']

  master_script = "#{node['csd-tachyon']['install_dir']}/bin/monit/tachyon-master.sh"
  template master_script do
    source 'tachyon-master.sh.erb'
    mode 0744
    user tachyon_user
    group tachyon_user
    variables node['csd-tachyon']
  end

  # Register a "tachyon-master" alias for this host.
  ddns_conf = node['ddns'] || {}
  ddns_alias 'tachyon-master' do
    dns_master ddns_conf['master']
    domain ddns_conf['domain']
    debug true
    # Only register if DDNS is configured and if the host name itself is not "tachyon-master".
    only_if { ddns_conf['master'] && ddns_conf['domain'] && node['hostname'] != 'tachyon-master' }
  end

  # Run Tachyon master with Monit
  service_name = 'tachyon-master'
  clearstorydata_monit_monitor service_name do
    template_source "monit/tachyon-service.conf.erb"
    template_cookbook 'clearstorydata-amplab'
    variables node['csd-tachyon'].merge(:main_class => 'tachyon.Master',
                                        :runner_script => master_script)
  end

  clearstorydata_monit_notify_if_not_running service_name

  clearstorydata_monit_service service_name do
    subscribes :restart, "clearstorydata_package[#{node['csd-tachyon']['pkg_name']}]", :delayed
    subscribes :restart, "clearstorydata-monit_monitor[#{service_name}]", :delayed
    subscribes :restart, "clearstorydata-monit_notify_if_not_running[#{service_name}]", :delayed
    subscribes :restart, "template[#{master_script}]", :delayed
  end
end
