if node['csd-tachyon']['enabled']

  if node['csd-tachyon']['java_debug_enabled']
    include_recipe "clearstorydata::find-free-port"
  end

  tachyon_user = node['csd-tachyon']['user']
  user_account tachyon_user do
    comment      "Tachyon"
    create_group true
    ssh_keygen   false
  end

  unless node['csd-tachyon']['master_hostname']
    if node['ddns'] && node['ddns']['master'] && node['ddns']['domain']
      node.default['csd-tachyon']['master_hostname'] = "tachyon-master.#{node['ddns']['domain']}"
    else
      raise "Please set node['csd-tachyon']['master_hostname'] or configure DNS"
    end
  end

  unless node['csd-tachyon']['hdfs_uri']
    node.default['csd-tachyon']['hdfs_uri'] = node['hadoop']['core_site']['fs.defaultFS']
  end

  clearstorydata_package node['csd-tachyon']['pkg_name'] do
    version node['csd-tachyon']['version']
    pkg_path node['csd-tachyon']['pkg_path']
  end

  install_dir = node['csd-tachyon']['install_dir']

  if node['csd-tachyon']['conf_dir']
    conf_dir = node['csd-tachyon']['conf_dir']
  else
    conf_dir = ::File.join(install_dir, 'conf')
    node.default['csd-tachyon']['conf_dir'] = conf_dir
  end

  log_dir = node['csd-tachyon']['log_dir']

  [conf_dir, log_dir, ::File.join(install_dir, 'bin/monit')].each do |dir|
    directory dir do
      mode 0755
      owner tachyon_user
      group tachyon_user
      action :create
      recursive true
    end
  end

  log_dir_symlink = ::File.join(install_dir, 'logs')
  link log_dir_symlink do
    to log_dir
    owner tachyon_user
    group tachyon_user
    not_if { log_dir == log_dir_symlink }
  end

  template ::File.join(conf_dir, 'tachyon-env.sh') do
    source "tachyon-env.sh.erb"
    mode 0644
    owner tachyon_user
    group tachyon_user
    variables node['csd-tachyon'].merge(:hadoop_conf_dir => node['hadoop']['conf_dir'])
  end

  bash "fix-tachyon-permissions" do
    # Make all scripts in the Tachyon installation directory executable by the Tachyon user/group.
    code "chgrp -R #{tachyon_user} #{install_dir.inspect}; " +
         "find #{install_dir.inspect} -perm -0400 -exec chmod g+x {} \\;"
  end

else
  Chef::Log.info("node['csd-tachyon']['enabled'] is not set, not installing Tachyon")
end
