---
title: Building and Testing Database Extensions
subtitle: With Nix
author: John Children
date: 26th October 2018
theme: Madrid
colortheme: dolphin
fontsize: 10
header-includes:
  - \usepackage{cmbright}
---

# Talk outline

Going to describe how I build extensions for PostgreSQL and Redis.

. . .

More of a description than a prescription.

# Why

Extension systems can be very flexible.

Three examples from PostgreSQL:

- citus
- postgis
- timescaledb

All three change a lot about the way PostgreSQL works.

::: notes
citus - scaling, distribution
postgis - support for geographical objects
timescaledb - timeseries data
pipelinedb - alternative timeseries data

postgresql is kind of exceptional in this regard.
:::

# Caveat

Extensions will only work with the major release they are compiled against.

# Motivating example

Co-worker adds new extension and updates major release dependency.

. . .

Forgets to update the major extension in the Dockerfile.

. . .

It builds but the extension won't load.

# Proposition

Can we try using Nix to do this?

::: notes
We hadn't really used it for anything before
:::

# Workflow prior to Nix

Install PostgreSQL server dev package via apt etc

. . .

Install other dev packages for my dependencies

. . .

Build the project locally

. . .

Build a docker image with the build output

. . .

Start the docker image as a local container

. . .

Run your tests against the service

::: notes
somewhat contrived example obviously

Obviously I could probably just write a script for doing this, but then I have to maintain the script

Skipped tooling installation

Docker multi stage builds can alleviate this a bit
:::

# Just write a bash script?

. . .

Sure, but what if I want to just run benchmarks

. . .

Or if I want to only run a specific test?

. . .

What if I want to just connect to an instance of the database with a terminal client and mess around?

# Just write a complicated bash script?

I'm kind of lazy though

. . .

Can I just push it to the CI pipeline and see what happens?

# Testing prior to Nix

Download dependencies in runner (if not pre-installed).

. . .

Wait for extensions to build

. . .

Wait for docker image to build

. . .

Wait for docker image to be uploaded to registry

. . .

Wait for docker image to be started as a service

. . .

Wait for tests to fail

::: notes

Add additional time for each job depending on how busy CI runners are.

:::

# Updating prior to Nix

Update the documentation with installation requirements

. . .

Update the docker image base with the new version

. . .

Update your local development packages

. . .

Update your remote build environment

::: notes
Do this every major release.
:::

# Aside: Module compatibility

How does PostgreSQL stop you loading extensions that aren't compatible?

# #PG_MODULE_MAGIC

- PostgreSQL uses a macro to fill a "magic" struct with information about an extension.
- This is activated by using the #PG_MODULE_MAGIC macro.
- This prevents from loading extensions that were compiled against other major PostgreSQL releases.

#

## Magic Struct

```c
/* Definition of the magic block structure */
typedef struct
{
   int         len;            /* sizeof(this struct) */
   int         version;        /* PostgreSQL major version */
   int         funcmaxargs;    /* FUNC_MAX_ARGS */
   int         indexmaxkeys;   /* INDEX_MAX_KEYS */
   int         namedatalen;    /* NAMEDATALEN */
   int         float4byval;    /* FLOAT4PASSBYVAL */
   int         float8byval;    /* FLOAT8PASSBYVAL */
} Pg_magic_struct;
```

::: notes
Just some extra information about how this is done.
:::

# Building a typical C extension

PGXS is a toolkit provided for building and distributing extensions.

## PXGS Makefile

```make
MODULES = isbn_issn
EXTENSION = isbn_issn
DATA = isbn_issn--1.0.sql
DOCS = README.isbn_issn

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
```

::: notes
Just lets you define an extension name and a definition

location of sql files with instructions on how to load it.

Also need a control file with extra meta information.

pg_config is a PostgreSQL binary

Locations for regression tests would also sit here

Not all extensions use PGXS, notable postgis but works well for simple projects.
:::


## Loading C Extensions

```sql
CREATE FUNCTION add_one(integer) RETURNS integer
     AS 'DIRECTORY/funcs', 'add_one'
     LANGUAGE C STRICT;
```

::: notes
example loading of a C extension

this is where you specify the language of the extension

also works for types
:::

# TL;DR: It's just a Makefile

And Nixpkgs is pretty good at handling Makefiles.

# Writing our expression

Just like a typical C Makefile:

- Extra build inputs can be linked through LDFLAGS in PGXS
- Custom flags can also be specified with CFLAGS.
- However: they are a bit of a pain to override due to pg_config.

::: notes
pg_config is a binary that tells you how PostgreSQL is configured.
:::

#

## Configuration Example

```bash
  preConfigure = ''
    configureFlagsArray=(
      --datadir=$out/share
      --datarootdir=$out/share
      --bindir=$out/bin
    )
    makeFlagsArray=(
      datadir=$out/share
      pkglibdir=$out/lib
      bindir=$out/bin
      CFLAGS="--std=c11 $(pg_config --cflags)"
      LDFLAGS="-lxxhash $(pg_config --ldflags)"
    );
  '';
```

::: notes
Using flags like this is probably bad practice, but I haven't found a better way with PGXS

Not many extensions in nixpkgs actually use PGXS and I'm not sure why.
:::

#

## Example Expression

```nix
{ stdenv, postgresql, xxHash }:

stdenv.mkDerivation rec {
  name = "myextension-${version}";
  version = "1.0";
  src = ./.;

  nativeBuildInputs = [ postgresql ];
  buildInputs = [ xxHash ];
  preConfigure = ''
    ... snip ...
  '';
}
```

::: notes
that's all you need!

okay so building it was easy, how do we actually use it?

how do we make this available to PostgreSQL?
:::

# PostgreSQL extensions in Nixpkgs

Expressions exist for a few useful extensions including

- postgis
- timescaledb
- postgres-hll
- pg_similarity
- pg_cron

The NixOS PosgreSQL module can be configured with a list of extensions.

::: notes

Postgis is actually a bit weird and is considered a library

Most nixpkgs extensions will just copy the build outputs directly rather than use PGXS to "install"

:::


# New Problem

## Question

How do we actually use this extension?

## Answer

Copy the way NixOS does it.

#

## postgresqlAndPlugins definition

```nix
postgresqlAndPlugins = pg:
    if cfg.extraPlugins == [] then pg
    else pkgs.buildEnv {
      name = "postgresql-and-plugins-${(builtins.parseDrvName pg.name).version}";
      paths = [ pg pg.lib ] ++ cfg.extraPlugins;
      buildInputs = [ pkgs.makeWrapper ];
      postBuild =
        ''
          mkdir -p $out/bin
          rm $out/bin/{pg_config,postgres,pg_ctl}
          cp --target-directory=$out/bin \
            ${pg}/bin/{postgres,pg_config,pg_ctl}
          wrapProgram $out/bin/postgres --set NIX_PGLIBDIR $out/lib
        '';
};
```

::: notes

cfg.extraPlugins is just a list of extra derivations

:::

# What is NIX_PGLIBDIR ?

Nixpkgs makes a small change to the way PostgreSQL finds extensions with a patch.

## Patching libraries

```c
char const * const nix_pglibdir = getenv("NIX_PGLIBDIR");
if(nix_pglibdir == NULL)
  make_relative_path(ret_path, LIBDIR, PGBINDIR, my_exec_path);
else
  make_relative_path(ret_path, nix_pglibdir, PGBINDIR, my_exec_path);
```

#

So just set $NIX_PGLIBDIR to our extensions build output?

. . .

Doesn't work if you want bundled extensions.

#

## Adapted PostgreSQL environment

```nix
  custom_postgres = let pg = pkgs.postgresql100; in pkgs.buildEnv {
    name = "custom-postgresql";
    paths = [ pg pg.lib (pkgs.callPackage ./extensions.nix { postgresql = pg; }) ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm -rf $out/bin
      mkdir -p $out/bin
      cp --target-directory=$out/bin \
        ${pg}/bin/{postgres,pg_config,pg_ctl,initdb,createdb}
      wrapProgram $out/bin/postgres --set NIX_PGLIBDIR $out/lib
    '';
  };
```

::: notes

note extra utilities initdb and createdb, we will be using them for testing.

they do end up in the final closure, but I find this reasonably acceptable for my use case.

but now I have binaries I can use to create and start dbs

:::

# Enter nix-shell

So if I have access to creating and initializing databases I can run just start a PostgreSQL instance on my system?

Sure, but that would be a pain to manage.

# How I use nix-shell

Build environment with:

- my database package
- my testing dependencies
- other tooling

::: notes

Probably not intended use of nix-shell

Testing dependencies are python packages from Nixpkgs + extras

:::

# Testing notes

- Using temporary databases seems to fit really well with Nix.
- Property based testing is really useful for custom datatype encoding/decoding.
- Pytest fixtures can be really handy for controlling database state.

::: notes

Ephemeral databases seem to work really well with testing this kind of thing

:::

# Results

Can now test our extension with just:

```bash
> nix-shell
> pytest
```

or alternatively

```bash
> nix-shell --pure --command "pytest"
```

::: notes

Much easier to use with much quicker feedback on what went wrong.

Pretty decent developer ergonomics

:::

# Updating

So now what happens if I want to change/update PostgreSQL versions?

. . .

Just change the PostgreSQL package.

::: notes

Just change the package in one place

Somewhat importantly can now use my extension with any nix packaged postgresql

Haven't had need for a build grid though

Obviously you might need to update your pinned nixpkgs if you are changing version.

:::

# Improvements

- No obvious way to run PGXS regression tests.
- `testing.postgresql` is fragile.
- Some better approaches like pg_tmp (bash) and tmp-postgres (haskell)
- Always overriding.

::: notes
Some kind of joke about leaking databases
:::

# Overview of Redis module system

Redis also has a module system!

Redis modules are responsible for loading and initializing themselves.

The API is versioned rather than being bound to each release

You have to write your own Makefile (etc).


::: notes

current api version is 1

:::

# Redis modules in Nixpkgs

???

::: notes
Haven't actually seen any yet. Could be wrong.

I don't know how you would load them anyway.
:::

# Building modules

## Example default.nix

```nix
{ stdenv }:

stdenv.mkDerivation rec {
  name = "mymodule-${version}";
  version = "0.1";

  makeFlags = [ "PREFIX=$(out)" ];

  src = ./.;
}
```

::: notes
even more straightforward
:::

# Testing

Good news: There is also a `testing.redis`!

. . .

Small caveat: need to set the REDIS_MODULES_PATH in shell.nix

##

```nix
shellHook = ''
  export REDIS_MODULES_PATH=${redis_modules}
'';
```

# Docker

It's inevitable.

# PostgreSQL

Can't layer on top of library image with dockerTools due to finding library dir.

Was building from scratch dockerTools for a while, but have reverted to using a Dockerfile.

. . .

## A horrible hack

```bash
rsync result/ build/ -a --copy-links -v
```

# Redis

Easy enough, just need to include a loadmodule command in config

::: notes

If you've read the Nixpkgs manual you'll have seen that building a docker image with redis is the canonical buildImage example.

:::

##

```
redisConfig = pkgs.writeText "redis.conf" ''
  loadmodule /lib/mymodule.so
'';
```

##

```
  Cmd = [ "/bin/redis-server" "${redisConfig}"];
```

. . .

But still not great!

# Bonus!

You can run the same tests on the images you've produced as a final check!

# Improvements

Need a better way to push the images after I've built them.

Need finer control of layers to prevent registry bloat.

Would really like to stop using rsync in CI.

::: notes
I'm just copying the tarball and then loading it in another runner.

buildLayeredImage seems to work here

Docker socket restrictions prevent me from pushing directly
:::

# Closing thoughts

![someone on hackernews yesterday](images/hackernews.png)

# Acknowledgments

## Justin Woo for helping me setup my slides pipeline

Cool little example repo:

github.com/justinwoo/easy-markdown-beamer-pandoc

# Thank you

github.com/johnchildren

twitter.com/johnchildren

## Slides at
github.com/johnchildren/presentations
