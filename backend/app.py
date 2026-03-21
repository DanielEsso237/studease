from flask import Flask, request, Response, jsonify
from flasgger import Swagger
from flask_cors import CORS
import requests
from dotenv import load_dotenv
import os

from db import db
from models.user import User
from routes.auth import auth_bp

load_dotenv()

app = Flask(__name__)
CORS(app)
swagger = Swagger(app)

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("La variable DATABASE_URL n'est pas définie dans le fichier .env")

app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URL
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db.init_app(app)


with app.app_context():
    db.create_all()

app.register_blueprint(auth_bp)


API_KEY = os.getenv("OPENROUTER_API_KEY")
if not API_KEY:
    raise ValueError("La variable OPENROUTER_API_KEY n'est pas définie dans le fichier .env")

MODEL = "stepfun/step-3.5-flash:free"


@app.route('/chat', methods=['POST'])
def chat():
    """
    Envoie un message à StepFun: Step 3.5 (streaming supporté)
    ---
    tags:
      - Chat
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          properties:
            message:
              type: string
            stream:
              type: boolean
              default: false
    responses:
      200:
        description: Réponse (stream ou JSON)
      400:
        description: Message manquant
      500:
        description: Erreur
    """
    data = request.get_json()
    if not data or 'message' not in data:
        return jsonify({"error": "Le champ 'message' est obligatoire"}), 400

    user_message = data['message']
    stream_requested = data.get('stream', False)

    url = "https://openrouter.ai/api/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "http://localhost",
        "X-Title": "Studease Chat"
    }
    payload = {
        "model": MODEL,
        "messages": [{"role": "user", "content": user_message}],
        "stream": stream_requested
    }

    try:
        resp = requests.post(
            url, json=payload, headers=headers,
            stream=stream_requested, timeout=90
        )

        if not stream_requested:
            resp.raise_for_status()
            result = resp.json()
            return jsonify({"response": result['choices'][0]['message']['content']})

        def generate():
            for chunk in resp.iter_lines():
                if chunk:
                    decoded = chunk.decode('utf-8')
                    if decoded.startswith('data: '):
                        yield decoded + '\n\n'
                    elif decoded == 'data: [DONE]':
                        yield 'data: [DONE]\n\n'
                        break

        return Response(generate(), mimetype='text/event-stream')

    except requests.exceptions.RequestException as e:
        error_text = e.response.text if e.response else str(e)
        return jsonify({"error": f"Erreur OpenRouter: {error_text}"}), 500


if __name__ == '__main__':
    print("Backend démarré sur http://127.0.0.1:5000")
    print("Swagger: http://127.0.0.1:5000/apidocs")
    app.run(debug=True, host='0.0.0.0', port=5000)