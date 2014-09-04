#
# Cookbook Name:: eucalyptus
# Recipe:: default
#
#Copyright [2014] [Eucalyptus Systems]
##
##Licensed under the Apache License, Version 2.0 (the "License");
##you may not use this file except in compliance with the License.
##You may obtain a copy of the License at
##
##    http://www.apache.org/licenses/LICENSE-2.0
##
##    Unless required by applicable law or agreed to in writing, software
##    distributed under the License is distributed on an "AS IS" BASIS,
##    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##    See the License for the specific language governing permissions and
##    limitations under the License.
##
#
include_recipe "eucalyptus::default"
## Install binaries for the CC
if node["eucalyptus"]["install-type"] == "packages"
  yum_package "eucalyptus-cc" do
    action :upgrade
    options node['eucalyptus']['yum-options']
    flush_cache [:before]
    notifies :start, "service[eucalyptus-cc]", :immediately
  end
  ### Compat for 3.4.2 and 4.0.0
  yum_package "dhcp"
else
  include_recipe "eucalyptus::install-source"
end

template "eucalyptus.conf" do
  path   "#{node["eucalyptus"]["home-directory"]}/etc/eucalyptus/eucalyptus.conf"
  source "eucalyptus.conf.erb"
  action :create
end

service "eucalyptus-cc" do
  action [ :enable, :start ]
  supports :status => true, :start => true, :stop => true, :restart => true
end

ruby_block "Register nodes" do
  cluster_name = Eucalyptus::KeySync.get_local_cluster_name(node)
  nc_ips = node['eucalyptus']['topology']['clusters'][cluster_name]['nodes'].split()
  Chef::Log.info "Node list is: #{nc_ips}"
  nc_ips.each do |nc_ip|
    r = Chef::Resource::Execute.new('Register Nodes', node.run_context)
    r.command "#{node['eucalyptus']['home-directory']}/usr/sbin/euca_conf --register-nodes #{nc_ip} --no-scp --no-rsync --no-sync"
    r.run_action :run
  end
end
