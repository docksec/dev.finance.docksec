from flask import Flask, jsonify, json

app = Flask(__name__)

@app.route('/metrics')
def get_metrics():
  with open('trivy_results.json', 'r') as f:
    data = json.load(f)
  return jsonify(data)

if __name__ == '__main__':
  app.run(port=5000)
