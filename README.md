## start the frontend

```bash
make frontend-install
make frontend-build
make frontend-bundle
make frontend-serve
```

## start the server

```bash
./build-psc-packages.sh
make server-build
make server-install
make server-run
```

Right now you need to decide in advance what backend you want to run because compilation is all happening
when the server startes up and is causing a ton of duplicate module errors. The default in the Makefile is
`core`, but to use `halogen` for example you can do

```bash
BACKEND=halogen make server-run

```

## run in docker

```bash
docker run --rm -i -t -p 80:80 $MORE_OPTIONS docker.kube-system.svc.cluster.local/blinky3713/trypurescript:latest
```

where the following `$MORE_OPTIONS` apply
* `-e BACKEND=backend_choice` - to pass in the $BACKEND environment variable allowing you to use a different backend (default is `core`)

You can then hit the container by going to http://localhost/ (port 80). Note that while the frontend will serve almost instantly, the backend takes a few seconds to warm up and compile the purescript for the backend of your choosing...
