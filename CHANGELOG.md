## next

* Upgraded Sidekiq requirement to >= 8.0 as [the storage format for
  `created_at` and `enqueued_at` was
  changed](https://github.com/sidekiq/sidekiq/blob/main/Changes.md#800) (#51)

  The `created_at`, `enqueued_at`, `failed_at` and `retried_at` attributes are
  now stored as epoch milliseconds, rather than epoch floats.  This is meant to
  avoid precision issues with JSON and JavaScript's 53-bit Floats.  Example:
  `"created_at" => 1234567890.123456` -> `"created_at" => 1234567890123`.

## 1.3.0

* Upgraded to Ruby 3.4/Sidekiq 7.3 on e2e test suite (#50)

## 1.2.1

* Upgraded to Ubuntu 24.04 on Github Actions (#49)

## 1.2.0

* Upgraded to PostgreSQL 15.2 and Redis 7.0 (#25)
* Upgraded PostgreSQL to 16.4 (#27)
* Upgraded PostgreSQL to 16.6 (#28)
* Upgraded PostgreSQL to 17.2 (#29)
* Switched from Redis to Valkey (#30)
* Upgraded PostgreSQL to 17.4 (#31)
* Upgraded PostgreSQL to 17.5 (#32)
* Upgraded to PostgreSQL 17.6 and Valkey 8.1 (#33)
* Upgraded PostgreSQL to 18.1 (#45)

## 1.1.0

* Migrated from Travis CI to Github Actions (#11)

## 1.0.1

* Do not remove the meta.user data from a MUC packet in order to not interfere
  with other modules (eg. mod_unread)

## 1.0.0

* Added a check for the affiliated users meta data of a packet
* Fixed the CI setup

## 0.2.0

* Added the (sender/receiver(s)) vCards on the XML event messages
  which are passed to Sidekiq jobs first argument

## 0.1.0

* Implemented the basic MAM to Sidekiq bridge
