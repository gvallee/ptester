# ptester
PRRTE test harness and module generator.

# Background

This tool has been developed in the context of a project where it was necessary
to execute many tasks on a parallel computer such as Summit at ORNL. To achieve
that goal, it was decided to rely on PRRTE and more precisely the 'prte' and
'prun' command in order to execute workloads composed of tasks once a job
allocation is assigned to a user.
In that context, this tool was developed to ensure that all target use-cases
are correctly supported and help detect performance regressions and bugs as
early as possible.

In addition, this tool provides a script for the generation of a PRRTE module,
in other terms, a tool that compile and install PRRTE in leadership computing
environments (but should be applicable to other environments). This also ensures
that the version of PRRTE that is tested is configured and installed in a
deterministic manner.

# Overview

The goal so far was to provide all the mechanisms to test different use cases of PRRTE-DVM on OLCF systems. This implies a few constraints:
- support different execution platforms,
- provide a tool that can easily support new use cases (more details further below) that reflect needs for new users that are not already covered,
- for this tool, prefer to rely on a programming language that is available on all target OLCF platforms,
- make sure that the test are pass/fail so it can later be integrated with MTT. Note that we are not at the moment looking at extending MTT to support this new execution model (i.e., "run a job in a job") since it would imply more coordinated work with the MTT team for little benefit. We believe having a separate tool that could be used in MTT to test DVM capabilities is a cleaner and more efficient option (that point can be discussed though).

# Compution platform configuration

The target systems for testing have had very different configurations from the
begining of the project. There is therefore a need to decouple to definition
of specifics related to the target platforms from the actual code of the tool.
As a result, we opted for a traditional design where configuration files for
each type of target platform is defined upfront. Note that ptester provides a
set of configuration files for the execution platforms that were initially 
targeted; users and developers should feel free to define their own
configuration file customized to their target platform.

# Use cases

The goal is to test different use cases relying on the distributed virtual machine capabilities of PRRTE. This use cases are driven by application teams' feedback, at the moment mainly from ORNL and the RADICAL team (http://radical.rutgers.edu).

## Supported use cases

### Many nodes; use all local cores but no oversubscription); short living applications

The goal of this use case is to test the scalability when using as many nodes as possible on a platform, while using all the computing resources (cores at the moment) on compute nodes. The test shall fail if all the nodes on the platform (or at least a target number of nodes) cannot be used to run a simple /bin/hostname on each node of the allocation.

### Future use cases

#### Many nodes; oversubscription; short living applications

The goal of this use case is to test the scalability of DVM when using as many nodes as possible with oversubscription and short leaving applications. The workload will be predefined (many tasks model) and the test will discover the upper limit in term of number of nodes to run the test. The test will succeed if the upper limit is equal or superior to the target number of nodes for a given platform. The idea behind this test is also to assume that users can submit a large number of sub-jobs and DVM will throttle the sub-job execution to guarantee large throughput (we do not have any quantitative requirements regarding the throughput at the moment).

#### Many nodes; no oversubscription; many application with random run times

The goal of this use case is to test the scalability of DVM when using as many nodes as possible with no oversubscription and applications that run for a random amount of time. The number of tasks will be predefined but the total execution time required by the workload will be defined at runtime. The goal of this test is to evaluate the robustness of the infrastructure when running different types of applications.

### Resource Manager Interaction

Because of the environment at our center, integration with job/resource managers is mandatory (we cannot rely only on tests that require interactive sessions). This implies the need for an architecture where various resource/job managers can easily be added.

## Current state

A simple proof-of-concept has been developed and used for evaluation on OLCF systems. The current version has been developed in Perl, the only programming language available on all target platforms when the project started. The programming language choice could be reconsidered at this time.

Developments are based on an incremental approach, meaning that only the first supported use case is currently implemented. Testing is at the moment focusing on the Summitdev system at ORNL and once we will be able to pass our first test on the entire system, that test will be executed at larger scale on Summit, while other use cases will be implemented and tested on Summitdev.
