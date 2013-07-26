# If this directory is two or more levels deep, permissions will be set on its parent
# directory as well. This assumes that the parent directory is also exclusive to Tachyon,
# e.g. /tachyon in the default case.
default["csd-tachyon"]["hdfs_data_dir"] = "/tachyon/data"

default["csd-tachyon"]["enabled"] = false
default["csd-tachyon"]["install_dir"] = "/usr/share/tachyon-hadoop2"
default["csd-tachyon"]["log_dir"] = "/var/log/tachyon"
default["csd-tachyon"]["master_heap_size_mb"] = 128
default["csd-tachyon"]["master_hostname"] = nil  # This is set using DNS by default.
default["csd-tachyon"]["master_port"] = 19998
default["csd-tachyon"]["pkg_name"] = "tachyon-hadoop2"
default["csd-tachyon"]["ram_folder"] = "/mnt/ramdisk"
default["csd-tachyon"]["ramfs_size_mb"] = 512
default["csd-tachyon"]["user"] = "spark"
default["csd-tachyon"]["worker_heap_size_mb"] = 128
default["csd-tachyon"]["worker_mem_mb"] = 512
