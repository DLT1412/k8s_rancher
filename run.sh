#!/bin/sh
ADMIN_PASSWORD=admin_password
CLUSTER_NAME=sandbox
K8S_VERSION=v1.20.6-rancher1-1
RANCHER_SERVER=rancher_server
EXPOSED_HTTPS_PORT=443
EXPOSED_HTTS_PORT=80
NUM_OF_WORKER=2

docker compose down -v
cp docker-compose.yaml.template docker-compose.yaml
sed -i '' "s|__RANCHER_SERVER__|$RANCHER_SERVER|" docker-compose.yaml
sed -i '' "s|__EXPOSED_HTTPS_PORT__|$EXPOSED_HTTPS_PORT|" docker-compose.yaml
sed -i '' "s|__EXPOSED_HTTP_PORT__|$EXPOSED_HTTP_PORT|" docker-compose.yaml
sed -i '' "s|__NUM_OF_WORKER__|$NUM_OF_WORKER|" docker-compose.yaml

docker compose up -d

cp config_master.sh.template config_master.sh
sed -i '' "s|__RANCHER_SERVER__|$RANCHER_SERVER|" config_master.sh
sed -i '' "s|__ADMIN_PASSWORD__|$ADMIN_PASSWORD|" config_master.sh
sed -i '' "s|__K8S_VERSION__|$K8S_VERSION|" config_master.sh
sed -i '' "s|__CLUSTER_NAME__|$CLUSTER_NAME|" config_master.sh
docker cp config_master.sh $RANCHER_SERVER:/
docker exec -it $RANCHER_SERVER /bin/sh -c "sh /config_master.sh"

_arr_worker=($(docker compose ps | grep worker | awk '{print $1}'))
for _worker in ${_arr_worker[@]}
do
  if [[ "$_worker" == *worker_1 ]]
  then
    ROLEFLAGS="--etcd --worker --controlplane"
  else
    ROLEFLAGS="--worker"
  fi
  cp config_worker.sh.template config_worker.sh
  sed -i '' "s|__RANCHER_SERVER__|$RANCHER_SERVER|" config_worker.sh
  sed -i '' "s|__ADMIN_PASSWORD__|$ADMIN_PASSWORD|" config_worker.sh
  sed -i '' "s|__CLUSTER_NAME__|$CLUSTER_NAME|" config_worker.sh
  sed -i '' "s|__ROLEFLAGS__|$ROLEFLAGS|" config_worker.sh
  docker cp config_worker.sh $_worker:/
  docker exec -it $_worker /bin/sh -c "sh /config_worker.sh"
done