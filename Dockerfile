FROM node:8.15-stretch
RUN apt update && apt install -y nginx && rm -rf /var/apt/lists/*
RUN curl -sSL https://get.haskellstack.org/ | sh
RUN npm install -g purescript bower pulp psc-package --unsafe-perm=true
RUN echo '{ "allow_root": true }' > /root/.bowerrc
COPY . /opt/trypurescript
WORKDIR /opt/trypurescript
RUN stack setup && ./build-psc-packages.sh && make frontend-install frontend-build frontend-bundle server-build server-install && rm -rf /root/.stack .stack-work
RUN ln -s /opt/trypurescript/docker/nginx.conf /etc/nginx/conf.d/default.conf
ENV PATH /root/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
CMD /opt/trypurescript/docker/start.sh
