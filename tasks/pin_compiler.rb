#!/opt/puppetlabs/puppet/bin/ruby
require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'puppet'
require 'net/http'

Puppet.initialize_settings

# Turn comma separated agents into an array
agents = JSON.parse(ARGF.read)['agent_certnames'].split(',')

# Create a Net::HTTP object and set the auth to use our certificates
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
http.cert = OpenSSL::X509::Certificate.new(File.read(Puppet.settings['hostcert']))
http.key = OpenSSL::PKey::RSA.new(File.read(Puppet.settings['hostprivkey']))
http.ca_file = Puppet.settings['localcacert']

# Get the id of the 'PE Master' node group
uri = URI.parse('https://localhost:4433/classifier-api/v1/groups')
res = http.request_get(uri.request_uri).read_body
master_id = JSON.parse(res).find { |group| group['name'] == 'PE Master' }['id']

# use the /pin endpoint to pin our compile masters to PE Master
uri = URI.parse('https://localhost:4433/classifier-api/v1/groups/%s/pin' % master_id)
req = Net::HTTP::Post.new(uri)
req.content_type = 'application/json'
req.body = { 'nodes' => agents }.to_json

http.request(req)
print({ 'status' => 'success' }.to_json)
