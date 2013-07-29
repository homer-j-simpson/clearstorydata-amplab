include_recipe 'clearstorydata-amplab::tachyon-install'

if node['csd-tachyon']['enabled']
  include_recipe 'ddns::register-hostname'

  tachyon_user = node['csd-tachyon']['user']

  # Create HDFS directories and set permissions.
  tachyon_hdfs_dir = node['csd-tachyon']['hdfs_data_dir']
  execute "Create #{tachyon_hdfs_dir} on HDFS" do
    user "hdfs"
    group "hdfs"
    command hdfs_dir_create_cmd(tachyon_hdfs_dir)
  end

  # Set permissions on the Tachyon data directory, but also on its parent directory, if the data
  # directory is not a top-level one. This assumes that the parent directory is exclusive to
  # Tachyon as well, e.g. /tachyon in the default case when hdfs_data_dir is set to /tachyon/data.
  [::File.dirname(tachyon_hdfs_dir), tachyon_hdfs_dir].each do |dir|
    execute "Set permissions on #{dir}" do
      user "hdfs"
      group "hdfs"
      command hdfs_chown_cmd("#{tachyon_user}:#{tachyon_user}", dir) + " && " +
              hdfs_chmod_cmd("a+rx", dir)
      not_if { dir == '/' }
    end
  end

  master_script = ::File.join(node['csd-tachyon']['install_dir'], 'bin/monit/tachyon-master.sh')
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
    subscribes :restart, "template[#{node['csd-tachyon']['conf_dir']}/tachyon-env.sh]", :delayed
  end
end
