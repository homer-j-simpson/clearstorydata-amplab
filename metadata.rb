name             "clearstorydata-amplab"
maintainer       "ClearStory Data"
maintainer_email "mbautin@clearstorydata.com"
license          "All rights reserved"
description      "ClearStory Data AmpLab stack recipes"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "2.3.0"

recipe "clearstorydata-amplab::tachyon-install", "Installs Tachyon on the node"
recipe "clearstorydata-amplab::tachyon-master", "Sets up Tachyon master using Monit"
recipe "clearstorydata-amplab::tachyon-worker", "Sets up Tachyon worker using Monit"

depends "clearstorydata"
depends "monit_wrapper", "~> 3.2"
depends "cloudera", "~> 2.0"

%w{ debian ubuntu }.each do |os|
  supports os
end
