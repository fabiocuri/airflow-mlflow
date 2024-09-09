from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from airflow.utils.dates import days_ago
import subprocess

def run_training_script():
    subprocess.run(['python', '/opt/airflow/dags/train_model.py'])

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': days_ago(1),
    'retries': 1,
}

dag = DAG(
    dag_id='train_model_dag',
    default_args=default_args,
    description='A simple DAG to train a model and store in MLflow',
    schedule_interval='@daily',
)

train_model_task = PythonOperator(
    task_id='train_model_task',
    python_callable=run_training_script,
    dag=dag,
)

train_model_task
