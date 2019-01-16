#!/bin/bash

cd ./staging/core && psc-package build && cd ../..;
cd ./staging/behaviors &&  psc-package build && cd ../..;
cd ./staging/halogen && psc-package build && cd ../..;
