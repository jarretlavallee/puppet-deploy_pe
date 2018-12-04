function deploy_pe::master_package_name(
  Hash $node_facts,
  String $version,
) >> String {
  $platform_tag = deploy_pe::platform_tag($node_facts)

  "puppet-enterprise-${version}-${platform_tag}.tar.gz"
}
