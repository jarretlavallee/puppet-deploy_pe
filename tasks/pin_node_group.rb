#!/opt/puppetlabs/puppet/bin/ruby
require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'puppet'
require 'net/http'

Puppet.initialize_settings

# Turn comma separated agents into an array
uri = URI.parse('https://localhost:4433/classifier-api/v1/groups')
params = JSON.parse(ARGF.read)
agents = params['agent_certnames'].split(',')
node_group = params['node_group']
raise 'node_group not specified' if node_group.nil?
raise 'agents not specified' if agents.nil?

# Create a Net::HTTP object and set the auth to use our certificates
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
http.cert = OpenSSL::X509::Certificate.new(File.read(Puppet.settings['hostcert']))
http.key = OpenSSL::PKey::RSA.new(File.read(Puppet.settings['hostprivkey']))
http.ca_file = Puppet.settings['localcacert']

# Get the id of the node group
res = http.request_get(uri.request_uri).read_body
node_group_id = JSON.parse(res).find { |group| group['name'] == node_group }['id']
raise "No group ID could be found for #{node_group}" if node_group_id.nil?

# use the /pin endpoint to pin our node to the specified group
uri = URI.parse('https://localhost:4433/classifier-api/v1/groups/%s/pin' % node_group_id)
req = Net::HTTP::Post.new(uri)
req.content_type = 'application/json'
req.body = { 'nodes' => agents }.to_json

http.request(req)
print({ 'status' => 'success' }.to_json)
