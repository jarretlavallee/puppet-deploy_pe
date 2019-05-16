# An example plan to provision an agent and sign the certificate
plan deploy_pe::provision_agent (
  TargetSpec $master,
  TargetSpec $nodes,
#  Optional[Array[Pattern[/\\w+=\\w+/]]] $custom_attribute = undef,
#  Optional[Array[Pattern[/\\w+=\\w+/]]] $extension_request = undef,
#  Optional[String] $dns_alt_names = undef,
#  Optional[String] $environment = undef,
) {
    # TODO: Format output
    # TODO: Check that we are running as root/Administrator.
    # TODO: Handle errors

    $master.apply_prep
    notice('Updating facts for nodes')
    without_default_logging() || { run_plan(facts, nodes => $nodes) }
    get_targets($nodes).each |$target| {
      $target_facts = $target.facts()
      if $target_facts['aio_agent_version'] == undef {
        # Update Master facts if needed
        if get_targets($master)[0].facts()['fqdn'] == undef {
          notice("Updating facts for ${master}")
          without_default_logging() || { run_plan(facts, nodes => $master) }
        }
        $master_fqdn = get_targets($master)[0].facts()['fqdn']
        if $master_fqdn == undef {
          fail_plan("Unable to get Master FQDN while bootstrapping ${target.name}. Is it online and configured?")
        }

        $bootstrap_task = $target_facts['os']['family'].downcase ? {
          'windows' => 'bootstrap::windows',
          default => 'bootstrap::linux'
        }

        # The pe_repo class for Ubuntu does not have the decimals in the version
        $platform = regsubst(deploy_pe::platform_tag($target_facts, true), '\.', '')
        run_command(
          "/opt/puppetlabs/puppet/bin/puppet apply -e \"include pe_repo::platform::${platform}\"",
          $master,
          "Ensuring ${platform} agent packages are available on ${master_fqdn}",
        )
        run_task(
          $bootstrap_task,
          $target,
          master => $master_fqdn,
#          custom_attribute => $custom_attribute,
#          extension_request => $extension_request,
#          dns_alt_names => $dns_alt_names,
#          environment => $environment,
        )
        $target_certname = run_task(
          'puppet_conf',
          $target,
          'Getting the certname for the agent',
          action => 'get',
          setting => 'certname'
        ).find($target.name).value['status']
        without_default_logging() || { run_plan(facts, nodes => $target) }
        run_task(
          'sign_cert::sign_cert',
          $master,
          agent_certnames => $target_certname
        )
      } else {
        notice('Already Bootstrapped')
      }
    }
}
