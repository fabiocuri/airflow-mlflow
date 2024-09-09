import mlflow
import mlflow.sklearn
from sklearn.datasets import make_regression
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split

# Create dataset
X, y = make_regression(n_samples=100, n_features=1, noise=0.1)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)

# Train model
model = LinearRegression()
model.fit(X_train, y_train)

# Log parameters and model
with mlflow.start_run():
    mlflow.log_param("model_type", "LinearRegression")
    mlflow.log_param("train_size", len(X_train))
    mlflow.sklearn.log_model(model, "model")
