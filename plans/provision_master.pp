# An example plan to install PE on one or more nodes
plan deploy_pe::provision_master (
  String $version = '2018.1.5',
  String $base_url = 'http://pe-releases.puppetlabs.lan',
  TargetSpec $nodes,
  Optional[Hash] $pe_settings = {password => 'puppetlabs'}, # See the settings in pe.conf.epp
  Optional[String] $download_url = undef,
) {

  # TODO: Format output
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

    $pe_conf_content = epp(
      'deploy_pe/pe.conf.epp',
      $pe_settings,
    )

    # Store the pe_conf content in a file created by `mktemp`
    # Ship this file off to /tmp on the master
    $tmp = run_command('mktemp', 'localhost', '_run_as' => system::env('USER'))
    $tmp_file = $tmp.first.value['stdout'].chomp
    $tmp_dest = sprintf('/tmp/%s', $tmp_file.basename)
    file::write($tmp_file, $pe_conf_content)
    upload_file($tmp_file, $tmp_dest, $target)

    $tarball = run_task(
      'deploy_pe::download_file',
      $target,
      'Downloading the PE tarball',
      url => $url
    )

    run_task(
      'deploy_pe::install_pe',
      $target,
      'Installing PE, this may take a while',
      tarball => $tarball.first.value['output_file'],
      pe_conf => $tmp_dest
    )

    run_task('deploy_pe::run_agent', $target)
  }
}
