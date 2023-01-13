<div align="center">
  <p align="center">
      <a href="https://turnly.app" target="_blank" rel="noopener">
          <img src="https://raw.githubusercontent.com/turnly/turnly/develop/docs/assets/github-header.png" />
      </a>
  </p>

  <p>
    <sub>
      Built with ❤︎ by
      <a href="https://github.com/turnly/turnly/blob/develop/OWNERS.md">
        maintainers
      </a>
    </sub>
  </p>
</div>

# Compose — Docker Operator

Docker Compose Operator for infrastructure provisioning and deployment of your self-hosted Turnly server.

### System Requirements

You need the following installed in your system:

- [Docker CE >=20.10.21](https://docs.docker.com/engine/release-notes)
- [Docker Compose >=2.15.1](https://docs.docker.com/compose/release-notes)
- [Git](https://git-scm.com/downloads)

### Clone the repository on your server

Clone these resources to your previously configured server with the basic requirements.

> 💡 TIP: Clone these resources to /opt/ directory

```sh
# Let's rename the directory where the resources will be cloned, in this case "turnly".
git clone https://github.com/turnly/ops-compose turnly
```

___

### Environment Variables

Environment variables will allow you to customize Turnly's configurations. \
You must change the environment variables before running Turnly using the Docker Compose.

```sh
# Go to the directory where you cloned the resources.
cd /opt/turnly/

# Now copy the `.env.example` file and set the variables appropriately.
cp .env.example .env
```
#### Secret keys

Generate secure secret keys, we recommend generating them with `openssl`.

| Secret                             | Value                        |
| ---------------------------------- | ---------------------------- |
| `OAUTH_ENCRYPTION_KEY`             | Run `openssl rand -hex 16`   |
| `OAUTH_SIGNING_KEY`                | Run `openssl rand -hex 16`   |
| `OAUTH_OIDC_CLIENT_SECRET`         | Run `openssl rand -hex 16`   |
| `OAUTH_ADMIN_OIDC_CLIENT_SECRET`   | Run `openssl rand -hex 16`   |
| `OAUTH_ADMIN_SIGNING_KEY`          | Run `openssl rand -hex 16`   |
| `OAUTH_ADMIN_ENCRYPTION_KEY`       | Run `openssl rand -hex 16`   |

#### Passwords

Generate strong passwords for your database instances and IAM, we recommend generating \
them with [1Password Generator.](https://1password.com/password-generator)

| Password                 | Value                |
| ------------------------ | :------------------: |
| `IAM_ADMIN_PASSWORD`     | __*** **** ***__     |
| `REDIS_PASSWORD`         | __*** **** ***__     |
| `MONGO_PASSWORD`         | __*** **** ***__     |
| `MINIO_ROOT_PASSWORD`    | __*** **** ***__     |
| `POSTGRES_PASSWORD`      | __*** **** ***__     |

#### Securing your Infra Dashboards

We expose several ports to the Internet, the main default ports are `80` and `443` which are
used for traffic from Turnly applications. However, other ports remain exposed for internal
use by your engineering team, ready for monitoring and resources management.

You can see the list of ports here: [Gateway configuration](/gateway.yml#L57)

> 🚨 If you plan to deploy these ports to the Internet, we suggest you put it behind a Virtual Private Network.

| Name                         | Assigned Port  | Description                                             |
| ---------------------------- | :------------: | ------------------------------------------------------- |
| `MONGO_UI_PORT`              | 6020           | The MongoDB dashboard port for resources management     |
| `POSTGRES_ADMINER_PORT`      | 6030           | The Postgres dashboard port for resources management    |
| `ELASTICSEARCH_UI_PORT`      | 6040           | The Kibana dashboard port for debugging & tracing       |
| `REDIS_UI_PORT`              | 6050           | The Redis dashboard port for resources management       |
| `MINIO_UI_PORT`              | 6060           | The Storage dashboard port for resources management     |
| `RABBITMQ_UI_PORT`           | 6070           | The RabbitMQ dashboard port for debugging               |
| `TRACING_UI_PORT`            | 6080           | The Tracing dashboard port for tracing & debugging      |

___

### Deploy, Get the services up and running.

After successfully setting your environment variables, you can get the Turnly using the following command:

```sh
bash compose.sh start
```

___

### Stop running containers.

You can stop and remove containers created for Turnly services using the `stop` command. \
The only things removed are containers for Turnly services.

```sh
bash compose.sh stop
```

___

### Upgrading version

To make updates to our services, we implement a basic strategy that allows us to do it
with **zero-downtime** whenever possible. Thanks to our **gateway**, we can scale the services
and load a new container with the new image while the **load balancer** sends requests
to both services for x time until we finally remove the old service leaving the new container.

You can upgrade your Turnly instances by using the following command:

> 💡 TIP: The infrastructure services are not restarted by default.
> If you want to upgrade them, run this command with the `--upgrade-all` flag.

```sh
# Pulling latest version of Compose Operator.
git pull origin main

# Run upgrade command
bash compose.sh upgrade
```

Pulling a specific version of Compose Operator.

```sh
# Pulling version.
git fetch --all --prune --quiet && git checkout $APP_VERSION

# Run upgrade command
bash compose.sh upgrade
```

Forcing upgrade

> 💡 TIP: If your current version is the same as the latest version and you still
> want to force a restart with the zero-downtime strategy, you can use the `--force` flag to proceed.

```sh
# Run upgrade command
bash compose.sh upgrade --force

# Run upgrade and include the infra services
bash compose.sh upgrade --upgrade-all --force
```

___

### Pruning (Dangerous)

Delete all containers, **data** and infrastructure from your server.

> Use this command with **caution** and do not add it to automated pipelines,
> preferably run it manually within your server.

```sh
bash compose.sh prune

# Add --images flag to cleanup all images
bash compose.sh prune --images
```

___

### Sponsors

If you are planning on using Turnly for your business and want to give back to the
team or if you are an organization looking to help emerging open-source
software, please consider [becoming a Github Sponsor](https://github.com/sponsors/efraa).
