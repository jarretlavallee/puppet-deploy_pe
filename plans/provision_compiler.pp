# @summary A plan to install an compiler from the master
#
# @param master
#  The TargetSpec for the Master from which to use the installer script
# @param targets
#  The TargetSpec of one or more compilers to be installed
# @example Install the PE agent on a node and configure it as a compiler
#  bolt plan run 'deploy_pe::provision_compiler' --run-as 'root' --params '{"master":"pe-master"}' --targets 'pe-compiler'
plan deploy_pe::provision_compiler (
  TargetSpec $master,
  TargetSpec $targets,
  #  Optional[Array[Pattern[/\\w+=\\w+/]]] $custom_attribute = undef,
  #  Optional[Array[Pattern[/\\w+=\\w+/]]] $extension_request = undef,
  #  Optional[String] $dns_alt_names = undef,
  #  Optional[String] $environment = undef,
  Optional[Boolean] $legacy_compiler = true,
  ) {
    get_targets($targets).each |$target| {
      run_plan('deploy_pe::provision_agent', master => $master, targets => $target)
      $target_certname = run_task(
        'puppet_conf',
        $target,
        'Getting the certname for the agent',
        action => 'get',
        setting => 'certname'
      ).find($target.name).value['status']
      if $legacy_compiler == true {
        run_task('deploy_pe::pin_node_group', $master, node_group => 'PE Master', agent_certnames => $target_certname)
        run_task('deploy_pe::run_agent', $target)
        run_task('deploy_pe::run_agent', $master)
      } else
      {
        run_task('deploy_pe::pin_node_group', $master, node_group => 'PE Infrastructure Agent', agent_certnames => $target_certname)
        run_task('deploy_pe::run_agent', $target)
        run_task('deploy_pe::provision_newstyle_compiler', $master, compiler => $target_certname)
      }
    }
  }
