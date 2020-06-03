# @summary A plan to install an agent from the master
#
# @param master
#  The TargetSpec for the Master from which to use the installer script
# @param targets
#  The TargetSpec of one or more targets to be installed
# @example Install the PE agent on a node
#  bolt plan run 'deploy_pe::provision_agent' --run-as 'root' --params '{"master":"pe-master"}' --targets 'pe-agent'
plan deploy_pe::provision_agent (
  TargetSpec $master,
  TargetSpec $targets,
  Optional[String[1]] $compiler_pool_address = undef,
#  Optional[Array[Pattern[/\\w+=\\w+/]]] $custom_attribute = undef,
#  Optional[Array[Pattern[/\\w+=\\w+/]]] $extension_request = undef,
#  Optional[String] $dns_alt_names = undef,
#  Optional[String] $environment = undef,
) {
    # TODO: Format output
    # TODO: Check that we are running as root/Administrator.
    # TODO: Handle errors

    $master.apply_prep
    notice('Updating facts for targets')
    without_default_logging() || { run_plan(facts, targets => $targets) }
    get_targets($targets).each |$target| {
      $target_facts = $target.facts()
      if $target_facts['aio_agent_version'] == undef {
        # Update Master facts if needed
        if get_targets($master)[0].facts()['fqdn'] == undef {
          notice("Updating facts for ${master}")
          without_default_logging() || { run_plan(facts, targets => $master) }
        }
        $master_fqdn = $compiler_pool_address ? {
          undef => get_targets($master)[0].facts()['fqdn'],
          default => $compiler_pool_address,
        }
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
          setting => 'certname',
          section => 'agent'
        ).find($target.name).value['status']
        without_default_logging() || { run_plan(facts, targets => $target) }
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
