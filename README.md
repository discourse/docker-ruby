# docker-ruby

This repository contains the Dockerfile and GitHub Actions workflow for building Docker images with specific Ruby versions on Debian-based distributions. These images are primarily used for Discourse deployments.

## Usage

To use the Docker images built from this repository, pull them from DockerHub:

```sh
docker pull discourse/ruby:<ruby_version>-<debian_release>-slim
```

Replace `<ruby_version>` and `<debian_release>` with the desired versions. See https://hub.docker.com/r/discourse/ruby/tags
for available tags.

## Building

New versions are created by the Github action. You should use those. If you need to build a custom image for some unforeseen reason, the command would look like:

```sh
docker build -t discourse/ruby:<ruby_version>-<debian_release>-slim --build-arg DEBIAN_RELEASE=<debian_release> --build-arg RUBY_VERSION=<ruby_version> .
```

## License

This repository is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
