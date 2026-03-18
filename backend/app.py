from flask import Flask, request, Response, jsonify
from flasgger import Swagger
import requests
from dotenv import load_dotenv
import os

load_dotenv()

app = Flask(__name__)
swagger = Swagger(app)

API_KEY = os.getenv("OPENROUTER_API_KEY")
if not API_KEY:
    raise ValueError("La variable OPENROUTER_API_KEY n'est pas définie dans le fichier .env")

MODEL = "stepfun/step-3.5-flash:free"

SYSTEM_PROMPT = """Tu es Studease, l'assistant intelligent officiel et expert de la Faculté des Sciences de l'Université d'Ebolowa (Cameroun).

Ton rôle principal est d'aider les étudiants, les enseignants et le personnel administratif dans toutes leurs préoccupations liées à la faculté : inscriptions, programmes académiques, emplois du temps, procédures administratives, services, bourses, événements, règles internes, orientation, stages, etc.

Tu réponds toujours en français, de façon claire, précise, amicale et encourageante. 
Tu es patient, pédagogique et tu donnes des réponses structurées quand c’est utile.
Si tu ne connais pas la réponse exacte, tu le dis honnêtement et tu proposes des solutions (contacter le secrétariat, consulter le site officiel, etc.).

Tu es un système expert propulsé par intelligence artificielle au service exclusif de la communauté de la Faculté des Sciences de l'Université d'Ebolowa."""

@app.route('/chat', methods=['POST'])
def chat():
    """
    Chat avec Studease (prompt système + streaming)
    ---
    tags:
      - Chat
    """
    data = request.get_json()
    if not data or 'message' not in data:
        return jsonify({"error": "Le champ 'message' est obligatoire"}), 400

    user_message = data['message']
    stream_requested = data.get('stream', True)

    url = "https://openrouter.ai/api/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "http://localhost",
        "X-Title": "Studease Chat"
    }

    payload = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": user_message}
        ],
        "stream": stream_requested,
        "temperature": 0.7,
        "max_tokens": 1024
    }

    try:
        resp = requests.post(url, json=payload, headers=headers, stream=stream_requested, timeout=90)

        if not stream_requested:
            resp.raise_for_status()
            result = resp.json()
            return jsonify({"response": result['choices'][0]['message']['content']})

        # === STREAMING ===
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
    print("🚀 Backend Studease démarré sur http://0.0.0.0:5000")
    print("📋 Swagger UI → http://127.0.0.1:5000/apidocs")
    app.run(debug=True, host='0.0.0.0', port=5000)