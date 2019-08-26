# An example plan to install PE on one or more nodes
plan deploy_pe::provision_master (
  TargetSpec $nodes,
  Optional[String] $version = undef, # Version of PE to download
  Optional[String] $base_url = 'https://pm.puppetlabs.com/puppet-enterprise', # The base URL to download PE from
  Optional[String] $download_url = undef, # A specific URL to download the tarball
  Optional[String] $installer_tarball = undef, # The local tarball on the machine to use instead of downloading PE
  Optional[Hash] $pe_settings = {password => 'puppetlabs'}, # See the settings in pe.conf.epp
) {

  # TODO: Format output
  # TODO: Error handling
  if $installer_tarball == undef and $version == undef and $download_url == undef {
    fail('You must provide version and base_url, download_url, or installer_tarball')
  } elsif $installer_tarball != undef and ($version != undef or $download_url) {
    fail('You can either version and base_url to download a new tarball or installer_tarball to use one on the target system')
  }

  notice('Updating facts for nodes')
  without_default_logging() || { run_plan(facts, nodes => $nodes) }
  get_targets($nodes).each |$target| {
    $master_facts = get_targets($target)[0].facts()

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

    if $version != undef or $download_url != undef {
      # Download the tarball
      $package_name = deploy_pe::master_package_name($master_facts, $version)
      $url = $download_url ? {
        undef => "${base_url}/${$version}/${package_name}",
        default => $download_url,
      }
      $tarball = run_task(
        'deploy_pe::download_file',
        $target,
        'Downloading the PE tarball',
        url => $url
      )
      $tarball_dest = $tarball.first.value['output_file']
    } else {
      # Use the provided tarball
      $tarball_dest = $installer_tarball
    }

    run_task(
      'deploy_pe::install_pe',
      $target,
      'Installing PE, this may take a while',
      tarball => $tarball_dest,
      pe_conf => $tmp_dest
    )

    run_task('deploy_pe::run_agent', $target)
  }
}
