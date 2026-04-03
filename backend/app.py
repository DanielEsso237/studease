from flask import Flask, request, Response, jsonify
from flasgger import Swagger
from flask_cors import CORS
from flask_jwt_extended import JWTManager, jwt_required, get_jwt_identity
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import requests, json, threading
from datetime import datetime
from dotenv import load_dotenv
import os
from pypdf import PdfReader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_core.documents import Document
from db import db
from routes.auth import auth_bp
from routes.conversations import conv_bp
from routes.account import account_bp
from models.conversation import Conversation
from models.message import Message

load_dotenv()

app = Flask(__name__)
CORS(app)
swagger = Swagger(app)

limiter = Limiter(
    get_remote_address,
    app=app,
    default_limits=["200 per hour"],
    storage_uri="memory://"
)

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
app.register_blueprint(conv_bp)
app.register_blueprint(account_bp)

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

MAX_HISTORY = 10


def load_or_create_vectorstore():
    global vector_store

    if os.path.exists(INDEX_PATH):
        vector_store = FAISS.load_local(
            INDEX_PATH, embeddings, allow_dangerous_deserialization=True
        )
        return

    docs = []

    if not os.path.exists(PDF_FOLDER):
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
        except Exception:
            pass

    if docs:
        os.makedirs(os.path.dirname(INDEX_PATH), exist_ok=True)
        vector_store = FAISS.from_documents(docs, embeddings)
        vector_store.save_local(INDEX_PATH)


load_or_create_vectorstore()


def _generate_title(conv_id: int, user_message: str, assistant_message: str):
    try:
        payload = {
            "model": MODEL,
            "messages": [
                {
                    "role": "user",
                    "content": (
                        "Donne un titre court (5 mots maximum) qui résume cette conversation. "
                        "Réponds uniquement avec le titre, sans guillemets, sans ponctuation finale, "
                        "sans explication.\n\n"
                        f"User: {user_message}\n"
                        f"Assistant: {assistant_message[:300]}"
                    ),
                }
            ],
            "temperature": 0.3,
            "max_tokens": 20,
        }
        url = "https://openrouter.ai/api/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json",
            "HTTP-Referer": "http://localhost",
            "X-Title": "Studease Chat",
        }
        res   = requests.post(url, json=payload, headers=headers, timeout=15)
        title = res.json()['choices'][0]['message']['content'].strip()
        if title:
            with app.app_context():
                db.session.execute(
                    db.update(Conversation)
                    .where(Conversation.id == conv_id)
                    .values(title=title)
                )
                db.session.commit()
    except Exception:
        pass


@app.route('/chat', methods=['POST'])
@jwt_required()
@limiter.limit("30 per minute")
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
            conversation_id:
              type: integer
            stream:
              type: boolean
              default: true
    responses:
      200:
        description: Réponse streamée ou JSON
      400:
        description: Message manquant
      404:
        description: Conversation introuvable
      500:
        description: Erreur serveur
    """
    user_id = int(get_jwt_identity())
    data    = request.get_json()
    if not data or 'message' not in data:
        return jsonify({"error": "Le champ 'message' est obligatoire"}), 400

    user_message     = data['message']
    conv_id          = data.get('conversation_id')
    stream_requested = data.get('stream', True)

    if conv_id:
        conv = Conversation.query.filter_by(id=conv_id, user_id=user_id).first()
        if not conv:
            return jsonify({"error": "Conversation introuvable"}), 404
    else:
        title = user_message[:60] + ("…" if len(user_message) > 60 else "")
        conv  = Conversation(user_id=user_id, title=title)
        db.session.add(conv)
        db.session.commit()

    db.session.add(Message(conversation_id=conv.id, role='user', content=user_message))
    db.session.commit()

    raw_history = [
        {"role": m.role, "content": m.content}
        for m in conv.messages[:-1]
    ]
    history = raw_history[-MAX_HISTORY:]

    context = ""
    if vector_store:
        results = vector_store.similarity_search(user_message, k=4)
        raw_ctx = "\n\n".join(doc.page_content for doc in results)
        if raw_ctx.strip():
            context = (
                "Voici des extraits de ta base de connaissance interne sur la Faculté des Sciences "
                "de l'Université d'Ebolowa. Ces informations font partie de tes données officielles "
                "et tu peux les présenter comme telles, sans mentionner qu'elles proviennent de "
                "documents partagés par l'utilisateur :\n\n"
                + raw_ctx
                + "\n\nUtilise ces informations pour répondre de manière précise et factuelle. "
                "Présente toujours les informations comme faisant partie de ta connaissance "
                "de la faculté. Si le contexte ne contient pas la réponse, dis-le honnêtement "
                "sans faire référence à des documents ou extraits."
            )

    full_system_prompt = SYSTEM_PROMPT_BASE + ("\n\n" + context if context else "")

    payload = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": full_system_prompt},
            *history,
            {"role": "user", "content": user_message},
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
            answer = resp.json()['choices'][0]['message']['content']
            with app.app_context():
                db.session.add(Message(
                    conversation_id=conv.id, role='assistant', content=answer))
                db.session.execute(
                    db.update(Conversation)
                    .where(Conversation.id == conv.id)
                    .values(updated_at=datetime.utcnow())
                )
                db.session.commit()
            return jsonify({"response": answer, "conversation_id": conv.id})

        assistant_buffer = []
        is_first_exchange = len(conv.messages) <= 2

        def generate():
            yield f"data: {json.dumps({'conversation_id': conv.id})}\n\n"

            for chunk in resp.iter_lines():
                if not chunk:
                    continue
                decoded = chunk.decode('utf-8')
                if not decoded.startswith('data: '):
                    continue

                payload_str = decoded[6:].strip()

                if payload_str == '[DONE]':
                    full_answer = ''.join(assistant_buffer)
                    with app.app_context():
                        db.session.add(Message(
                            conversation_id=conv.id,
                            role='assistant',
                            content=full_answer
                        ))
                        db.session.execute(
                            db.update(Conversation)
                            .where(Conversation.id == conv.id)
                            .values(updated_at=datetime.utcnow())
                        )
                        db.session.commit()

                    if is_first_exchange:
                        threading.Thread(
                            target=_generate_title,
                            args=(conv.id, user_message, full_answer),
                            daemon=True
                        ).start()

                    yield 'data: [DONE]\n\n'
                    break

                try:
                    parsed = json.loads(payload_str)
                    delta  = parsed['choices'][0]['delta'].get('content', '')
                    if delta:
                        assistant_buffer.append(delta)
                except Exception:
                    pass

                yield decoded + '\n\n'

        return Response(generate(), mimetype='text/event-stream')

    except requests.exceptions.RequestException as e:
        error_text = e.response.text if e.response else str(e)
        return jsonify({"error": f"Erreur OpenRouter: {error_text}"}), 500


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)