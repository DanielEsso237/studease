from flask import Flask, request, Response, jsonify
from flasgger import Swagger
from flask_cors import CORS
from flask_jwt_extended import JWTManager
import requests
from dotenv import load_dotenv
import os
from pypdf import PdfReader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_core.documents import Document

from db import db
from models.user import User
from routes.auth import auth_bp

load_dotenv()

app = Flask(__name__)
CORS(app)
swagger = Swagger(app)


DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("DATABASE_URL n'est pas définie dans .env")

app.config['SQLALCHEMY_DATABASE_URI'] = DATABASE_URL
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False


JWT_SECRET = os.getenv("JWT_SECRET_KEY")
if not JWT_SECRET:
    raise ValueError("JWT_SECRET_KEY n'est pas définie dans .env")

app.config['JWT_SECRET_KEY'] = JWT_SECRET
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = False

db.init_app(app)
JWTManager(app)

with app.app_context():
    db.create_all()

app.register_blueprint(auth_bp)


API_KEY = os.getenv("OPENROUTER_API_KEY")
if not API_KEY:
    raise ValueError("OPENROUTER_API_KEY n'est pas définie dans .env")

MODEL = "stepfun/step-3.5-flash:free"


SYSTEM_PROMPT_BASE = """Tu es Studease, l'assistant intelligent officiel et expert de la Faculté des Sciences de l'Université d'Ebolowa (Cameroun).

Ton rôle principal est d'aider les étudiants, les enseignants et le personnel administratif dans toutes leurs préoccupations liées à la faculté : inscriptions, programmes académiques, emplois du temps, procédures administratives, services, bourses, événements, règles internes, orientation, stages, etc.

Tu réponds toujours en français, de façon claire, précise, amicale et encourageante. 
Tu es patient, pédagogique et tu donnes des réponses structurées quand c'est utile.
Si tu ne connais pas la réponse exacte, tu le dis honnêtement et tu proposes des solutions (contacter le secrétariat, consulter le site officiel, etc.).

Tu es un système expert propulsé par intelligence artificielle au service exclusif de la communauté de la Faculté des Sciences de l'Université d'Ebolowa."""


PDF_FOLDER = os.path.join(os.path.dirname(__file__), "pdfs")
INDEX_PATH  = os.path.join(os.path.dirname(__file__), "rag", "index.faiss")

embeddings   = HuggingFaceEmbeddings(model_name="sentence-transformers/all-MiniLM-L6-v2")
vector_store = None


def load_or_create_vectorstore():
    global vector_store

    if os.path.exists(INDEX_PATH):
        print("Chargement de l'index FAISS existant...")
        vector_store = FAISS.load_local(
            INDEX_PATH, embeddings, allow_dangerous_deserialization=True
        )
        return

    print("Création d'un nouvel index FAISS...")
    docs = []

    if not os.path.exists(PDF_FOLDER):
        print(f"Dossier PDF introuvable : {PDF_FOLDER} → RAG désactivé")
        return

    for filename in os.listdir(PDF_FOLDER):
        if not filename.lower().endswith(".pdf"):
            continue
        path = os.path.join(PDF_FOLDER, filename)
        try:
            reader = PdfReader(path)
            text = "".join(page.extract_text() or "" for page in reader.pages)
            splitter = RecursiveCharacterTextSplitter(
                chunk_size=800, chunk_overlap=150, length_function=len
            )
            for chunk in splitter.split_text(text):
                docs.append(Document(page_content=chunk, metadata={"source": filename}))
        except Exception as e:
            print(f"Erreur lecture {filename} : {e}")

    if docs:
        os.makedirs(os.path.dirname(INDEX_PATH), exist_ok=True)
        vector_store = FAISS.from_documents(docs, embeddings)
        vector_store.save_local(INDEX_PATH)
        print(f"Index FAISS créé avec {len(docs)} chunks.")
    else:
        print("Aucun PDF valide trouvé → RAG désactivé")


load_or_create_vectorstore()


@app.route('/chat', methods=['POST'])
def chat():
    """
    Envoie un message à Studease (RAG + streaming)
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
              default: true
    responses:
      200:
        description: Réponse streamée ou JSON
      400:
        description: Message manquant
      500:
        description: Erreur serveur
    """
    data = request.get_json()
    if not data or 'message' not in data:
        return jsonify({"error": "Le champ 'message' est obligatoire"}), 400

    user_message     = data['message']
    stream_requested = data.get('stream', True)

    context = ""
    if vector_store:
        results = vector_store.similarity_search(user_message, k=4)
        pieces  = [doc.page_content for doc in results]
        raw_ctx = "\n\n".join(pieces)
        if raw_ctx.strip():
            context = (
                "Contexte extrait des documents officiels de la faculté :\n"
                + raw_ctx
                + "\n\nUtilise ces informations pour répondre de manière précise "
                  "et factuelle. Si le contexte ne répond pas directement, dis-le honnêtement."
            )

    full_system_prompt = SYSTEM_PROMPT_BASE + ("\n\n" + context if context else "")

    payload = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": full_system_prompt},
            {"role": "user",   "content": user_message},
        ],
        "stream":      stream_requested,
        "temperature": 0.65,
        "max_tokens":  1200,
    }

    url = "https://openrouter.ai/api/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type":  "application/json",
        "HTTP-Referer":  "http://localhost",
        "X-Title":       "Studease Chat",
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
    print("Backend Studease démarré sur http://0.0.0.0:5000")
    print("Swagger UI → http://127.0.0.1:5000/apidocs")
    app.run(debug=True, host='0.0.0.0', port=5000)