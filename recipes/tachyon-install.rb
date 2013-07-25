if node['csd-tachyon']['enabled']
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
    conf_dir = "#{install_dir}/conf"
    node.default['csd-tachyon']['conf_dir'] = conf_dir
  end

  data_dir = node['csd-tachyon']['data_dir']
  log_dir = node['csd-tachyon']['log_dir']

  [conf_dir, data_dir, log_dir, install_dir + "/bin/monit"].each do |dir|
    directory dir do
      mode 0755
      owner tachyon_user
      group tachyon_user
      action :create
      recursive true
    end
  end

  log_dir_symlink = install_dir + '/logs'
  link log_dir_symlink do
    to log_dir
    owner tachyon_user
    group tachyon_user
    not_if { log_dir == log_dir_symlink }
  end

  data_dir_symlink = install_dir + '/data'
  link data_dir_symlink do
    to data_dir
    owner tachyon_user
    group tachyon_user
    not_if { data_dir == data_dir_symlink }
  end

  template "#{conf_dir}/tachyon-env.sh" do
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

  tachyon_dir = "/tachyon/data"
  execute "Create #{path} on HDFS" do
    user "hdfs"
    group "hdfs"
    command hdfs_dir_create_cmd(path)
  end

  execute "Set permissions on #{path}" do
    user "hdfs"
    group "hdfs"
    command hdfs_chown_cmd("#{tachyon_user}:#{tachyon_user}", path) + " && " +
            hdfs_chmod_cmd("a+rx", path)
  end

else
  Chef::Log.info("node['csd-tachyon']['enabled'] is not set, not installing Tachyon")
end
