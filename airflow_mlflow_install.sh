#!/bin/bash

# Install Apache Airflow

helm repo add apache-airflow https://airflow.apache.org

helm repo update

kubectl create namespace airflow

helm install airflow apache-airflow/airflow \
  --namespace airflow \
  --set airflow.image.tag=2.7.2 \
  --set airflow.executor=Local \
  --set airflow.config.airflowConfigMap.config='[core]\nexecutor = LocalExecutor'
  
kubectl port-forward svc/airflow-webserver 8080:8080 --namespace airflow &

# Install MLFlow

helm repo add community-charts https://community-charts.github.io/helm-charts

helm repo update

kubectl create namespace mlflow

helm install mlflow community-charts/mlflow

kubectl port-forward svc/mlflow 5000:5000 --namespace mlflow &

# Add train_model_dag.py inside of the dag folder

export AIRFLOW_WEBSERVER_POD=$(kubectl get pods --namespace airflow --selector="component=webserver" --output=jsonpath="{.items[0].metadata.name}")
kubectl exec -it $AIRFLOW_WEBSERVER_POD --namespace airflow -- /bin/bash
cat $AIRFLOW_HOME/airflow.cfg | grep dags_folder
# Make sure the result above is /opt/airflow/dags/ , otherwise change below
kubectl cp /home/fabio/Desktop/airflow_mlflow_tutorial/train_model_dag.py $AIRFLOW_WEBSERVER_POD:/opt/airflow/dags/ -n airflow
