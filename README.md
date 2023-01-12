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

Docker Compose Operator for the provision of infrastructures for stage or production environments.

### System Requirements

To properly set up the environment, ensure you meet the following requirements on your server:

- [Docker CE >=20.10.21](https://docs.docker.com/engine/release-notes)
- [Docker Compose >=2.15.1](https://docs.docker.com/compose/release-notes)

> In the future we would like to add some details about best practices and security of your application,
> however for now we recommend reading some articles on how to improve the security of your servers,
> access limitations, port blocking, VPC, Firewalls, etc.

### Clone the repository on your server

Clone these resources to your previously configured server with the basic requirements.

> 💡 TIP: For convenience, clone these resources to /opt/ directory

```sh
# Let's rename the directory where the resources will be cloned, in this case "turnly".
git clone https://github.com/turnly/ops-compose turnly
```

___

### Environment Variables

Environment variables will allow you to customize Turnly's configurations.
You must change the environment variables before running Turnly using the Docker Compose.

```sh
# Go to the directory where you cloned the resources.
cd /opt/turnly/

# Now copy the `.env.example` file and set the variables appropriately.
cp .env.example .env
```

__Use a different port range for your production environments. Default range is `6000-6090`.__

| Name                         | Assigned Port  | Description                                    |
| ---------------------------- | :------------: | ---------------------------------------------- |
| `APP_PORT`                   | 6000           | The exposed port for each application          |
| `MONGO_UI_PORT`              | 6020           | The MongoDB dashboard port for monitoring      |
| `POSTGRES_ADMINER_PORT`      | 6030           | The Postgres dashboard port for monitoring     |
| `ELASTICSEARCH_UI_PORT`      | 6040           | The Kibana dashboard port for monitoring       |
| `REDIS_UI_PORT`              | 6050           | The Redis dashboard port for monitoring        |
| `MINIO_UI_PORT`              | 6060           | The Storage dashboard port for monitoring      |
| `RABBITMQ_UI_PORT`           | 6070           | The RabbitMQ dashboard port for monitoring     |
| `TRACING_UI_PORT`            | 6080           | The Tracing dashboard port for monitoring      |

__Generate secure secret keys, we recommend generating them with `openssl`.__

| Secret                             | Value                        |
| ---------------------------------- | ---------------------------- |
| `OAUTH_ENCRYPTION_KEY`             | Run `openssl rand -hex 16`   |
| `OAUTH_SIGNING_KEY`                | Run `openssl rand -hex 16`   |
| `OAUTH_OIDC_CLIENT_SECRET`         | Run `openssl rand -hex 16`   |
| `OAUTH_ADMIN_OIDC_CLIENT_SECRET`   | Run `openssl rand -hex 16`   |
| `OAUTH_ADMIN_SIGNING_KEY`          | Run `openssl rand -hex 16`   |
| `OAUTH_ADMIN_ENCRYPTION_KEY`       | Run `openssl rand -hex 16`   |

__Generate strong passwords for your database instances and IAM, we recommend generating them with [1Password Generator.](https://1password.com/password-generator)__

| Password                 | Value                |
| ------------------------ | :------------------: |
| `IAM_ADMIN_PASSWORD`     | __*** **** ***__     |
| `REDIS_PASSWORD`         | __*** **** ***__     |
| `MONGO_PASSWORD`         | __*** **** ***__     |
| `MINIO_ROOT_PASSWORD`    | __*** **** ***__     |
| `POSTGRES_PASSWORD`      | __*** **** ***__     |

___

### Start

After successfully setting your environment variables, you can get the Turnly using the following Docker command:

```sh
sh ./compose.sh up
```

Ahoy, once the Docker installation completes, go to `accounts.${YOUR_DOMAIN}`
on your browser to access the IAM dashboard.

___

### Upgrading or switching version

To make updates to our services, we implement a basic strategy that allows us to do it
with **zero-downtime** whenever possible. Thanks to our **gateway**, we can scale the services
and load a new container with the new image while the **load balancer** sends requests
to both services for x time until we finally remove the old service leaving the new container.

You can upgrade your Turnly instances by using the following command:

> 💡 TIP: The infrastructure services are not restarted by default.
> If you want to upgrade them, run this command with the `--upgrade-all` flag.

```sh
# Pulling latest version of compose operator.
# WARNING: Make sure you don't have changes to your files to avoid merge conflicts.
git pull origin main

# Run upgrade command
sh ./compose.sh upgrade
```

Pulling a specific version of compose operator.

```sh
# Pulling version.
git fetch --all --prune --quiet && git checkout $APP_VERSION

# Run upgrade command
sh ./compose.sh upgrade
```

Forcing upgrade

> 💡 TIP: If your current version is the same as the latest version and you still
> want to force a reboot with the zero-downtime strategy, you can use the `--force` flag to proceed.

```sh
# Run upgrade command
sh ./compose.sh upgrade --force

# Run upgrade and include the infra services
sh ./compose.sh upgrade --upgrade-all --force
```

___

### Stop

You can stop your Turnly instances by using the following command:

```sh
sh ./compose.sh stop
```

___

### Uninstall (Dangerous)

You can permanently stop your Turnly instances and wipe your data from the volumes using the following command:

```sh
sh ./compose.sh down
```

___

### Sponsors

If you are planning on using Turnly for your business and want to give back to the
team or if you are an organization looking to help emerging open-source
software, please consider [becoming a Github Sponsor](https://github.com/sponsors/efraa).
