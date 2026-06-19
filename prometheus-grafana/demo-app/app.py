from flask import Flask, Response
from prometheus_client import Counter, Gauge, generate_latest, CONTENT_TYPE_LATEST
import random
import threading
import time

# App laeuft auf Port 8080
# Metriken werden bereitgestellt unter: http://<pod-ip>:8080/metrics
# Prometheus scrapt genau diesen Endpoint alle 15s (konfiguriert per ServiceMonitor)

app = Flask(__name__)

http_requests_total = Counter(
    'http_requests_total',
    'Total number of HTTP requests',
    ['method', 'endpoint']
)

active_users_gauge = Gauge(
    'active_users',
    'Number of currently active users in the system'
)

orders_processed_total = Counter(
    'orders_processed_total',
    'Total number of processed orders',
    ['status']
)


def simulate_background_activity():
    while True:
        active_users_gauge.set(random.randint(10, 200))
        if random.random() > 0.2:
            orders_processed_total.labels(status='success').inc()
        else:
            orders_processed_total.labels(status='error').inc()
        time.sleep(5)


@app.route('/')
def index():
    http_requests_total.labels(method='GET', endpoint='/').inc()
    return '<h1>Demo App</h1><p>Metriken: <a href="/metrics">/metrics</a></p>'


@app.route('/buy')
def buy():
    http_requests_total.labels(method='GET', endpoint='/buy').inc()
    orders_processed_total.labels(status='success').inc()
    return 'Order placed!'


@app.route('/metrics')
def metrics():
    http_requests_total.labels(method='GET', endpoint='/metrics').inc()
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


if __name__ == '__main__':
    t = threading.Thread(target=simulate_background_activity, daemon=True)
    t.start()
    app.run(host='0.0.0.0', port=8080)
