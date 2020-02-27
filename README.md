
# deploy_pe

A module of Bolt plans and tasks to facilitate a lab based installation of a monolithic PE stack.

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with deploy_pe](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with deploy_pe](#beginning-with-deploy_pe)
3. [Usage - Examples](#usage)
4. [Limitations](#limitations)
5. [Development](#development)

## Description

A module of Bolt plans and tasks to facilitate the installation of a monolithic PE stack. This module is designed to be used with the [Puppet Debugging Kit](https://github.com/puppetlabs/puppet-debugging-kit) to install a lab based PE stack.

Currently the module provides the following plans.

* Install a PE master
* Install an agent and sign the certificate on the master
* Install and configure a compiler

## Setup

### Setup Requirements

This module has only been tested on Linux and MacOS operating systems. The plans and tasks will likely not work from windows workstations. Please use the current version of Bolt to run these tasks and plans

The plans assume that there are no puppet components installed on the target machines. Only 2018.1+ versions of PE have been tested.

### Beginning with deploy_pe

## Usage

To use this module, install it in the `boltdir` and leverage the plans in the section below. The examples below will install a PE master, compiler, and agent.

Install a 2019.1.1 PE master with the `admin` password set to `puppetlabs`.

```bash
bolt plan run 'deploy_pe::provision_master' --run-as 'root' --params '{"version":"2019.1.1","pe_settings":{"password":"puppetlabs"}}' --targets 'pe-master'
```

The plan above will download the `2019.1.1` PE installer package, create a `pe.conf` with the password setting, and run the installer script to install PE.

Install an agent from the PE master.

```bash
bolt plan run 'deploy_pe::provision_agent' --run-as 'root' --params '{"master":"pe-master"}' --targets 'pe-agent'
```

The plan above will install the agent using the installer script from the master after ensuring that the agent packages are available on the master. It will then sign the agent's certificate on the master.

Install a compiler

```bash
bolt plan run 'deploy_pe::provision_compiler' --run-as 'root' --params '{"master":"pe-master"}' --targets 'pe-compiler'
```

The plan above will install the agent using the installer script from the master, pin the node to the `PE Master` node group, and then run the agent until there are no changes.

Purge a node from the master

```bash
bolt plan run 'deploy_pe::decom_agent' --run-as 'root' --params '{"master":"pe-master"}' --targets 'pe-agent'
```

The plan above will purge the node from the master. If the node is already offline it will try to guess the node name.

See the [REFERENCE.md](REFERENCE.md) for additional parameters.

## Limitations

This is only meant for lab based installations and not production installations. It is meant to be run with [vagrant-bolt](https://github.com/oscar-stack/vagrant-bolt) and using the [Puppet Debugging Kit](https://github.com/puppetlabs/puppet-debugging-kit)

## Development

PRs and issues are welcome.

## Contributors

Thank you @m0dular for the continued help on this module.
