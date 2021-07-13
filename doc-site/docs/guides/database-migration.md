---
title: Database migration
sidebar_label: Database migration
sidebar_position: 4
---

## Flyway
Database migrations are handled with [Flyway](https://flywaydb.org/). Migrations run in a docker container started in the Kubernetes cluster by CircleCI or the local dev environment startup process.

## Application
The migration job is defined in `kubernetes/migration/job.yml` and your SQL scripts should be in `database/migration/`.
Migrations will be automatically run against your dev environment when running `./start-dev-env.sh`. After merging the migration it will be run against other environments automatically as part of the pipeline.

## Conventions
The SQL scripts need to follow Flyway naming convention [here](https://flywaydb.org/documentation/concepts/migrations.html#sql-based-migrations), which allow you to create different types of migrations:
* Versioned - These have a numerically incrementing version id and will be kept track of by Flyway. Only versions that have not yet been applied will be run during the migration process.
* Undo - These have a matching version to a versioned migration and can be used to undo the effects of a migration if you need to roll back.
* Repeatable - These will be run whenever their content changes. This can be useful for seeding data or updating views or functions.

## Examples
Here are some example migrations:

`V1__create_tables.sql`
```sql
CREATE TABLE address (
    id INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    person_id INT(6),
    street_number INT(10),
    street_name VARCHAR(50),
    reg_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

`V2__add_columns.sql`
```sql
ALTER TABLE address
 ADD COLUMN city VARCHAR(30) AFTER street_name,
 ADD COLUMN province VARCHAR(30) AFTER city
```