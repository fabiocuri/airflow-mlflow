#!/bin/bash

# Create k8s cluster

sudo apt install docker.io

snap install kubectl --classic

[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

ip_addresses=$(hostname -I)
export MY_IP_ADDRESS=$(echo "$ip_addresses" | awk '{print $1}')
kind delete cluster --name kind
envsubst < cluster.yaml | kind create cluster --retain --config=-
kubectl cluster-info --context kind-kind

# Install Apache Airflow

helm repo add apache-airflow https://airflow.apache.org
helm repo update
kubectl create namespace airflow

helm install airflow apache-airflow/airflow \
  --namespace airflow \
  --set airflow.image.tag=2.7.2 \
  --set airflow.executor=Local \
  --set airflow.config.airflowConfigMap.config='[core]\nexecutor = LocalExecutor'
  
sleep 10

kubectl port-forward svc/airflow-webserver 8080:8080 --namespace airflow &

# Install MLFlow

helm repo add community-charts https://community-charts.github.io/helm-charts
helm repo update
kubectl create namespace mlflow

helm install mlflow community-charts/mlflow \
  --namespace mlflow

sleep 10

kubectl port-forward svc/mlflow 5000:5000 --namespace mlflow &

# Add train_model_dag.py inside of the dag folder

export AIRFLOW_SCHEDULER_POD=$(kubectl get pods --namespace airflow -l component=scheduler -o jsonpath="{.items[0].metadata.name}")
export AIRFLOW_WEBSERVER_POD=$(kubectl get pods --namespace airflow --selector="component=webserver" --output=jsonpath="{.items[0].metadata.name}")
kubectl exec -it $AIRFLOW_WEBSERVER_POD --namespace airflow -- /bin/bash
cat $AIRFLOW_HOME/airflow.cfg | grep dags_folder
# Make sure the result above is /opt/airflow/dags/ , otherwise change below
kubectl cp /home/fabio/Desktop/airflow-mlflow/train_model.py $AIRFLOW_WEBSERVER_POD:/opt/airflow/dags/ -n airflow
kubectl cp /home/fabio/Desktop/airflow-mlflow/train_model_dag.py $AIRFLOW_WEBSERVER_POD:/opt/airflow/dags/ -n airflow
airflow scheduler