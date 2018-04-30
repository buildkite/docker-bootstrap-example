# Example: Docker Bootstrap

This is an example of using a custom buildkite bootstrap script to run an entire Buildkite build inside an ephemeral docker container.

## Installing

Download `bootstrap.sh` and put it someone on your agent host. Set `bootstrap-script-path` to reference the bootstrap script. If running, you will need to restart your agent so it picks up the new config

## How it works

The Buildkite Agent invokes a "bootstrap" subprocess to handle each job. This is typically `buildkite-agent bootstrap`, which runs the entire process for a job from checkout, to plugins, to hooks. The output from the bootstrap script is what is sent to the UI on buildkite.com.

This provides a script that wraps the agent bootstrap process in an ephemeral docker container. This provides a level of protection against hostile scripts messing with the host that your buildkite-agent is run on.

## Security

At this stage, this is just a first line defense. There are still many aspects that we need to get right before it's safe to run third party builds.

### Access to Docker Socket

At present, the docker socket from the host isn't mounted into the container, as it can be used to access the host filesystem basically as root (or whatever the docker daemon is running at).

The plan is to private a proxied socket with https://github.com/buildkite/sockguard that locks down what the socket can be used for.

### Access to Local Network

Things running in the container can still access local network things which can lead to [SSRF attacks](https://www.owasp.org/index.php/Server_Side_Request_Forgery) that disclose things like Amazon's cloud meta-data endpoints or other secrets available over http.
