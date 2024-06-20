# docker-ruby

This repository contains the Dockerfile and GitHub Actions workflow for building Docker images with specific Ruby versions on Debian-based distributions. These images are primarily used for Discourse deployments.

## Usage

To use the Docker images built from this repository, pull them from DockerHub:

```sh
docker pull discourse/ruby:<ruby_version>-<debian_release>-slim
```

Replace `<ruby_version>` and `<debian_release>` with the desired versions. See https://hub.docker.com/r/discourse/ruby/tags
for available tags.

## License

This repository is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.
