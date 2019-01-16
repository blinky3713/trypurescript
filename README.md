## start the frontend

```bash

> make frontend-install
> make frontend-build
> make frontend-bundle
> make frontend-serve 

```

## start the server

```bash
> make server-build
> make server-install
> make server-run

```

Right now you need to decide in advance what backend you want to run because compilation is all happening
when the server startes up and is causing a ton of duplicate module errors. The default in the Makefile is
`core`, but to use `halogen` for example you can do

```bash
> BACKEND=halogen make server-run

```

