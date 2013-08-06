include_recipe 'clearstorydata-amplab::tachyon-install'

if node['csd-tachyon']['enabled']
  ram_folder = node['csd-tachyon']['ram_folder']
  tachyon_user = node['csd-tachyon']['user']

  directory ram_folder do
    mode 0755
    owner tachyon_user
    group tachyon_user
    recursive true
  end

  mount ram_folder do
    device '/dev/null'  # should be ramfs, but this works as a workaround for http://bit.ly/13701Ac
    fstype 'ramfs'
    options "size=#{node['csd-tachyon']['ramfs_size_mb']}m"
    action [:mount, :enable]
  end

  bash "fix permissions on #{ram_folder}" do
    code "chown #{tachyon_user}:#{tachyon_user} #{ram_folder}"
  end

  unless node['csd-tachyon']['worker_host']
    node.default['csd-tachyon']['worker_host'] = node['hostname']
  end

  if !node['csd-tachyon']['worker_mem_mb'] && node['csd-tachyon']['ramfs_size_mb']
    node.default['csd-tachyon']['worker_mem_mb'] = node['csd-tachyon']['ramfs_size_mb']
  end

  worker_script = ::File.join(node['csd-tachyon']['install_dir'], 'bin/monit/tachyon-worker.sh')
  template worker_script do
    source 'tachyon-worker.sh.erb'
    mode 0754  # this needs to be executable by both user and group
    user tachyon_user
    group tachyon_user
    variables node['csd-tachyon']
  end

  # Run Tachyon worker with Monit
  service_name = 'tachyon-worker'
  clearstorydata_monit_monitor service_name do
    template_source "monit/tachyon-service.conf.erb"
    template_cookbook 'clearstorydata-amplab'
    variables node['csd-tachyon'].merge(:main_class => 'tachyon.Worker',
                                        :runner_script => worker_script)
  end

  clearstorydata_monit_notify_if_not_running service_name

  clearstorydata_monit_service service_name do
    subscribes :restart, "clearstorydata_package[#{node['csd-tachyon']['pkg_name']}]", :delayed
    subscribes :restart, "clearstorydata-monit_monitor[#{service_name}]", :delayed
    subscribes :restart, "clearstorydata-monit_notify_if_not_running[#{service_name}]", :delayed
    subscribes :restart, "template[#{worker_script}]", :delayed
    subscribes :restart, "template[#{node['csd-tachyon']['conf_dir']}/tachyon-env.sh]", :delayed
  end
end
