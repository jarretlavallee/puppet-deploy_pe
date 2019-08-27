# @summary A plan to install a new PE master
#
# @param nodes
#  The TargetSpec of one or more masters to be installed
# @param version
#  The PE version to download from the $base_url.
#  The `$version`, `$download_url`, or `$installer_tarball` are mutually exclusive. Please choose only one option.
# @param base_url
#  The base of a HTTP URL that will be used to download the PE installer script.
#  The resuting format is `${base_url}/${$version}/${package_name}`.
# @param download_url
#  A direct HTTP link to the installer tarball.
#  The `$version`, `$download_url`, or `$installer_tarball` are mutually exclusive. Please choose only one option.
# @param installer_tarball
#  A path to the installer tarball on the target master. This option assumes that the tarball has already been downloaded on the target machine.
#  The `$version`, `$download_url`, or `$installer_tarball` are mutually exclusive. Please choose only one option.
# @param pe_settings
#  A hash of the settings to be used in the `pe.conf` during the installation.
#  The most common setting will be the `password`
#  All other settings can be found in the `templates/pe.conf.epp`
# @example Install a 2019.1.1 PE master on a node using `puppetlabs` as the password
#  bolt plan run 'deploy_pe::provision_master' --run-as 'root' --params '{"version":"2019.1.1","pe_settings":{"password":"puppetlabs"}}' --nodes 'pe-master'
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
