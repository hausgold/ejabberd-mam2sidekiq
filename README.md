![ejabberd MAM/Sidekiq Bridge](doc/assets/project.svg)

[![Test](https://github.com/hausgold/ejabberd-mam2sidekiq/actions/workflows/test.yml/badge.svg)](https://github.com/hausgold/ejabberd-mam2sidekiq/actions/workflows/test.yml)

This is a custom [ejabberd](https://www.ejabberd.im/) module which allows to
bridge all archived messages (from [Message Archive
Management/XEP-0313](https://xmpp.org/extensions/xep-0313.html)) to actual
[Sidekiq](https://sidekiq.org/)
[jobs](https://github.com/mperham/sidekiq/wiki/Job-Format) on a
[Redis](https://redis.io/) database. This enables third party applications to
work and react on messages without implementing a XMPP presence application
which must subscribe to all multi user chats. Furthermore this module allows
direct messages to be processed the same way as multi user chat messages on
third party applications. This module requires an activated [ejabberd
mod_mam](https://docs.ejabberd.im/admin/configuration/#mod-mam) to work,
because we listen for the storage hooks. They do not suffer from message
dupplication. (Copies, changing sender/receiver side)

- [Requirements](#requirements)
  - [Runtime](#runtime)
  - [Build and development](#build-and-development)
- [Installation](#installation)
- [Configuration](#configuration)
  - [Database](#database)
- [Development](#development)
  - [Getting started](#getting-started)
    - [mDNS host configuration](#mdns-host-configuration)
  - [Test suite](#test-suite)
- [Additional readings](#additional-readings)

## Requirements

### Runtime

* [ejabberd](https://www.ejabberd.im/) (=18.01)
  * Compiled Redis support (`--enable-redis` or [erlang-redis-client package](https://packages.ubuntu.com/bionic/erlang-redis-client) on [hausgold/ejabberd](https://hub.docker.com/r/hausgold/ejabberd) image)
* [Redis](https://redis.io/) (>=3.2)

### Build and development

* [GNU Make](https://www.gnu.org/software/make/) (>=4.2.1)
* [Docker](https://www.docker.com/get-docker) (>=17.09.0-ce)
* [Docker Compose](https://docs.docker.com/compose/install/) (>=1.22.0)

## Installation

See the [detailed installation instructions](./INSTALL.md) to get the ejabberd
module up and running. When you are using Debian/Ubuntu, you can use an
automatic curl pipe script which simplifies the installation process for you.

## Configuration

We make use of the global database settings of ejabberd, but you can also
specify a different database type by setting it explicitly.

```yaml
# Global Redis config
# See: https://docs.ejabberd.im/admin/configuration/#redis
redis_server: "redis.server.com"
redis_port: 6379
redis_db: 1

modules:
  mod_mam2sidekiq:
    sidekiq_queue: "default"
    sidekiq_class: "SomeWorker"
```

## Development

### Getting started

The project bootstrapping is straightforward. We just assume you took already
care of the requirements and you have your favorite terminal emulator pointed
on the project directory.  Follow the instructions below and then relaxen and
watchen das blinkenlichten.

```bash
# Installs and starts the ejabberd server and it's database
$ make start

# (The jabber server should already running now on its Docker container)

# Open a new terminal on the project path,
# install the custom module and run the test suite
$ make reload test
```

When your host mDNS Stack is fine, you can also inspect the [ejabberd admin
webconsole](http://jabber.local/admin) with
`admin@jabber.local` as username and `defaultpw` as password. In the
case you want to shut this thing down use `make stop`.

#### mDNS host configuration

If you running Ubuntu/Debian, all required packages should be in place out of
the box. On older versions (Ubuntu < 18.10, Debian < 10) the configuration is
also fine out of the box. When you however find yourself unable to resolve the
domains or if you are a lucky user of newer Ubuntu/Debian versions, read on.

**Heads up:** This is the Arch Linux way. (package and service names may
differ, config is the same) Install the `nss-mdns` and `avahi` packages, enable
and start the `avahi-daemon.service`. Then, edit the file `/etc/nsswitch.conf`
and change the hosts line like this:

```bash
hosts: ... mdns4 [NOTFOUND=return] resolve [!UNAVAIL=return] dns ...
```

Afterwards create (or overwrite) the `/etc/mdns.allow` file when not yet
present with the following content:

```bash
.local.
.local
```

This is the regular way for nss-mdns > 0.10 package versions (the
default now). If you use a system with 0.10 or lower take care of using
`mdns4_minimal` instead of `mdns4` on the `/etc/nsswitch.conf` file and skip
the creation of the `/etc/mdns.allow` file.

**Further readings**
* Archlinux howto: https://wiki.archlinux.org/index.php/avahi
* Ubuntu/Debian howto: https://wiki.ubuntuusers.de/Avahi/
* Further detail on nss-mdns: https://github.com/lathiat/nss-mdns

### Test suite

The test suite sets up a simple environment with 3 independent users. (admin,
alice and bob). A new test room is created by the admin user, as well as alice
and bob were made members by setting their affiliations on the room. (This is
the same procedure we use on production for lead/user/agent integrations on the
Jabber service) The suite sends then multiple text messagess. The Redis
database/queue contains then a job for each sent message.

The test suite was written in JavaScript and is executed by Node.js inside a
Docker container. We picked JavaScript here due to the easy and good featured
[stanza.io](http://stanza.io) client library for XMPP. It got all the things
which were needed to fulfil the job.

## Additional readings

* [mod_mam MUC IQ integration](http://bit.ly/2M2cSWl)
* [mod_mam MUC message integration](http://bit.ly/2Kx69iF)
* [mod_muc implementation](http://bit.ly/2AJTSYq)
* [mod_muc_room implementation](http://bit.ly/2LX6As4)
* [mod_muc_room IQ implementation](http://bit.ly/2LWgXfI)
* [muc_filter_message hook example](http://bit.ly/2Oey9K0)
* [MUC message definition](http://bit.ly/2MavaVo)
* [MUCState definition](http://bit.ly/2AM4CWi)
* [XMPP codec API docs](http://bit.ly/2LXQ235)
* [XMPP codec guide](http://bit.ly/2LHKFoq)
* [XMPP codec script example](http://bit.ly/2M8sgNM)
