# Auditing PostgreSQL with pgaudit 

---
pgAudit versions relate to PostgreSQL major versions as follows:

* pgAudit v16.X is intended to support PostgreSQL 16.
* pgAudit v1.7.X is intended to support PostgreSQL 15.
* pgAudit v1.6.X is intended to support PostgreSQL 14.
* pgAudit v1.5.X is intended to support PostgreSQL 13.
* pgAudit v1.4.X is intended to support PostgreSQL 12.

---

## Downtime
YES

```alter system set shared_preload_libraries = 'pgaudit';```

Alternative is to write ```set shared_preload_libraries = 'pgaudit'``` in a config file under PostgreSQL ```conf.d``` folder.

Anyways, both options need a ```systemctl restart postgresql```

## Required packages
```
Package: postgresql-13-pgaudit
Version: 1.5.2-1.pgdg110+1
Priority: optional
Section: database
Source: pgaudit-1.5
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Installed-Size: 106 kB
Depends: postgresql-13, libc6 (>= 2.4)
Homepage: http://pgaudit.org/
Download-Size: 47.4 kB
APT-Sources: http://apt.postgresql.org/pub/repos/apt bullseye-pgdg/main amd64 Packages
Description: PostgreSQL Audit Extension
 The pgAudit extension provides detailed session and/or object audit logging
 via the standard PostgreSQL logging facility.
 .
 The goal of pgAudit is to provide PostgreSQL users with capability to produce
 audit logs often required to comply with government, financial, or ISO
 certifications.
 .
 An audit is an official inspection of an individual's or organization's
 accounts, typically by an independent body. The information gathered by
 pgAudit is properly called an audit trail or audit log.
```

```
Package: postgresql-13-pgauditlogtofile
Version: 1.5.12-2.pgdg110+1
Priority: optional
Section: database
Source: pgauditlogtofile
Maintainer: Debian PostgreSQL Maintainers <team+postgresql@tracker.debian.org>
Installed-Size: 87.0 kB
Depends: libc6 (>= 2.4), postgresql-13, postgresql-13-jit-llvm (>= 11), postgresql-13-pgaudit
Homepage: https://github.com/fmbiete/pgauditlogtofile
Download-Size: 29.7 kB
APT-Sources: http://apt.postgresql.org/pub/repos/apt bullseye-pgdg/main amd64 Packages
Description: PostgreSQL pgAudit Add-On to redirect audit logs
 pgAudit Log to File is an addon to pgAudit than will redirect audit log lines
 to an independent file, instead of using PostgreSQL server logger.
 .
 This allows to have an audit file that we can easily rotate without polluting
 server logs with those messages.
 .
 Audit logs in heavily used systems can grow very fast. This extension allows
 to automatically rotate the files.
```

## Installation
 
 ```apt install postgresql-13-pgaudit postgresql-13-pgauditlogtofile```
 
## Configuration

### In database
```
CREATE EXTENSION pgaudit;
CREATE EXTENSION pgauditlogtofile;
```

### In filesystem
```vim /etc/postgresql/13/main/conf.d/10_audit.conf```

```
shared_preload_libraries = 'pgaudit'
pgaudit.log = 'none'
pgaudit.log_parameter = on
pgaudit.log_directory = 'audit'
pgaudit.log_filename = 'audit-%Y%m%d_%H%M.log'
pgaudit.log_rotation_age = 1440
pgaudit.log_connections = on
pgaudit.log_disconnections = on
```

## Starting
```systemctl restart postgresql```

## Dropping audit
```alter system set pgaudit.log = 'none';
drop extension pgaudit;
drop extension pgauditlogtofile;
```

```systemctl restart postgresql```

## Auditing a user
```
alter role olivier set pgaudit.log='all'
```