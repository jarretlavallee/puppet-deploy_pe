# Generate the PE installer package name
#
# @param node_facts
#  A hash of facts that will be used to get the OS version
# @param version
#  The version of PE
# @return [String] The name of the PE installer package based on the OS and PE version
function deploy_pe::master_package_name(
  Hash $node_facts,
  String $version,
  Boolean $fips = false,
  Optional[String] $extension = '.gz',
) >> String {
  $platform_tag = deploy_pe::platform_tag($node_facts, false, $fips)

  "puppet-enterprise-${version}-${platform_tag}.tar${extension}"
}
