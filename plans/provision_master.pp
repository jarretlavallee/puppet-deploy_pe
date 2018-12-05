# An example plan to install PE on one or more nodes
plan deploy_pe::provision_master (
  String $version = '2018.1.5',
  String $base_url = 'http://pe-releases.puppetlabs.lan',
  String $tmp_path = '/tmp',
  Optional[String] $download_url = undef,
  TargetSpec $nodes,
) {

    # TODO: Format output
    # TODO: Check that we are running as root.
    # TODO: Error handling

    notice('Updating facts for nodes')
    without_default_logging() || { run_plan(facts, nodes => $nodes) }
    get_targets($nodes).each |$target| {
      $master_facts = get_targets($target)[0].facts()
      $package_name = deploy_pe::master_package_name($master_facts, $version)
      $url = $download_url ? {
        undef => "${base_url}/${$version}/${package_name}",
        default => $download_url,
      }
      $tarball_path = "${tmp_path}/${package_name}"
      upload_file(
        'deploy_pe/pe.conf',
        "${tmp_path}/pe.conf",
        $target,
        'Uploading the pe.conf',
      )
      run_task(
        'deploy_pe::download_file',
        $target,
        'Downloading the PE tarball',
        url => $url,
        destination => $tarball_path,
      )
      run_task(
        'ref_arch_setup::install_pe',
        $target,
        'Installing PE, this may take a while',
        pe_tarball_path => $tarball_path,
        pe_conf_path => "${tmp_path}/pe.conf"
      )
    }
}
