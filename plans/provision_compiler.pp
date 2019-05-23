plan deploy_pe::provision_compiler (
  TargetSpec $master,
  TargetSpec $nodes,
  #  Optional[Array[Pattern[/\\w+=\\w+/]]] $custom_attribute = undef,
  #  Optional[Array[Pattern[/\\w+=\\w+/]]] $extension_request = undef,
  #  Optional[String] $dns_alt_names = undef,
  #  Optional[String] $environment = undef,
  ) {
    get_targets($nodes).each |$target| {
      run_plan('deploy_pe::provision_agent', master => $master, nodes => $target)
      $target_certname = run_task(
        'puppet_conf',
        $target,
        'Getting the certname for the agent',
        action => 'get',
        setting => 'certname'
      ).find($target.name).value['status']

      run_task('deploy_pe::pin_compiler', $master, agent_certnames => $target_certname)
      run_task('deploy_pe::run_agent', $target)
      run_task('deploy_pe::run_agent', $master)
    }
  }
