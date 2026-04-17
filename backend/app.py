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
from db import db
from routes.auth import auth_bp
from routes.conversations import conv_bp
from routes.account import account_bp
from models.conversation import Conversation
from models.message import Message
from pypdf import PdfReader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_core.documents import Document

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

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
if not GROQ_API_KEY:
    raise ValueError("GROQ_API_KEY n'est pas définie dans .env")

MODEL = "llama-3.3-70b-versatile"

SYSTEM_PROMPT_BASE = """Tu es Studease, l'assistant officiel et bienveillant de la Faculté des Sciences de l'Université d'Ebolowa (Cameroun).

Tu accompagnes chaleureusement les étudiants, enseignants et le personnel administratif sur tout ce qui touche à la faculté : inscriptions, programmes, emplois du temps, procédures administratives, services, bourses, événements, règlement intérieur, orientation, stages, et bien plus encore.

Tu as une personnalité amicale, patiente et encourageante. Tu t'adresses à l'utilisateur de façon naturelle et humaine, comme un conseiller de confiance qui connaît parfaitement la faculté.

RÈGLES QUE TU RESPECTES ABSOLUMENT ET SANS EXCEPTION :

1. Tu bases TOUJOURS tes réponses exclusivement sur les informations du contexte fourni. Tu ne complètes jamais avec des suppositions ou des connaissances extérieures.

2. Quand le contexte contient la réponse, tu la formules de façon claire, structurée et chaleureuse — comme si c'était une connaissance naturelle que tu as de la faculté. Tu ne mentionnes jamais l'existence de "documents", "extraits" ou "contexte".

3. Quand le contexte ne contient pas la réponse, tu le dis honnêtement mais avec bienveillance, par exemple : "Je n'ai pas encore cette information, mais je te conseille de contacter le secrétariat de la faculté ou de consulter le site officiel de l'Université d'Ebolowa — ils pourront t'aider rapidement 😊"

4. Tu ne réponds qu'aux questions qui concernent la Faculté des Sciences de l'Université d'Ebolowa. Si quelqu'un te demande autre chose, tu rappelles gentiment ton rôle : "Je suis dédié à la Faculté des Sciences de l'Université d'Ebolowa, donc je ne peux pas t'aider sur ce sujet — mais pour tout ce qui concerne la fac, je suis là !"

5. Tu n'inventes jamais de noms, de dates, de chiffres, de procédures ou de règles. Si une information n'est pas dans le contexte, elle n'existe pas pour toi.

6. Tu réponds toujours en français, avec un ton chaleureux et des formulations naturelles. Tu utilises le markdown pour structurer tes réponses quand c'est utile.

7. Tu utilises souvent des émojis pour être plus chaleureux et amical """

PDF_FOLDER = os.path.join(os.path.dirname(__file__), "pdfs")
INDEX_PATH = os.path.join(os.path.dirname(__file__), "rag", "index.faiss")
META_PATH  = os.path.join(os.path.dirname(__file__), "rag", "index.meta.json")

MAX_HISTORY = 10

vector_store = None
_rag_ready   = False
_rag_lock    = threading.Lock()


def _get_pdf_signatures() -> dict:
    sigs = {}
    if not os.path.exists(PDF_FOLDER):
        return sigs
    for f in os.listdir(PDF_FOLDER):
        if f.lower().endswith(".pdf"):
            sigs[f] = os.path.getsize(os.path.join(PDF_FOLDER, f))
    return sigs


def _index_is_stale() -> bool:
    if not os.path.exists(INDEX_PATH) or not os.path.exists(META_PATH):
        return True
    try:
        with open(META_PATH, "r") as fh:
            saved = json.load(fh)
        return saved != _get_pdf_signatures()
    except Exception:
        return True


def _save_meta():
    os.makedirs(os.path.dirname(META_PATH), exist_ok=True)
    with open(META_PATH, "w") as fh:
        json.dump(_get_pdf_signatures(), fh)


def _load_full_pdf(filename):
    path = os.path.join(PDF_FOLDER, filename)
    if not os.path.exists(path):
        return ""
    try:
        reader = PdfReader(path)
        text = "\n\n".join(page.extract_text() or "" for page in reader.pages)
        return text[:15000]  # limite pour éviter de dépasser le contexte
    except:
        return ""


def _should_use_fallback(user_message):
    keywords = ["transfert", "transféré", "l3", "l2", "dossier", "pièces", "composition", 
                "préinscription", "preinscription", "master", "licence 3", "licence 2"]
    msg_lower = user_message.lower()
    return any(kw in msg_lower for kw in keywords)


def _load_rag_background():
    global vector_store, _rag_ready

    embeddings = HuggingFaceEmbeddings(
        model_name="intfloat/multilingual-e5-large"
    )

    try:
        if not _index_is_stale():
            vs = FAISS.load_local(
                INDEX_PATH, embeddings, allow_dangerous_deserialization=True
            )
            print("[RAG] Index chargé depuis le cache ✓")
        else:
            print("[RAG] Changement détecté — reconstruction de l'index…")
            docs = []
            if os.path.exists(PDF_FOLDER):
                for filename in os.listdir(PDF_FOLDER):
                    if not filename.lower().endswith(".pdf"):
                        continue
                    path = os.path.join(PDF_FOLDER, filename)
                    try:
                        reader = PdfReader(path)
                        text = "".join(page.extract_text() or "" for page in reader.pages)
                        splitter = RecursiveCharacterTextSplitter(
                            chunk_size=800,
                            chunk_overlap=250,
                            separators=["\n\n", "\n###", "\n##", "\n• ", "\n- ", "\n"],
                            length_function=len
                        )
                        for chunk in splitter.split_text(text):
                            section = "general"
                            lower_chunk = chunk.lower()
                            if any(x in lower_chunk for x in ["licence 1", "l1"]):
                                section = "L1"
                            elif any(x in lower_chunk for x in ["licence 2", "licence 3", "l2", "l3", "transfert", "transféré"]):
                                section = "L2_L3_transfer"
                            elif "master" in lower_chunk:
                                section = "Master"

                            docs.append(
                                Document(
                                    page_content=chunk,
                                    metadata={
                                        "source": filename,
                                        "filename": filename,
                                        "section": section
                                    }
                                )
                            )
                        print(f"[RAG]   ✓ {filename}")
                    except Exception as e:
                        print(f"[RAG]   ✗ {filename} : {e}")

            if docs:
                os.makedirs(os.path.dirname(INDEX_PATH), exist_ok=True)
                vs = FAISS.from_documents(docs, embeddings)
                vs.save_local(INDEX_PATH)
                _save_meta()
                print(f"[RAG] Index reconstruit avec {len(docs)} chunks ✓")
            else:
                vs = None
                print("[RAG] Aucun PDF trouvé — RAG désactivé")

        with _rag_lock:
            vector_store = vs
            _rag_ready   = True

    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"[RAG] Erreur lors du chargement : {e}")
        with _rag_lock:
            _rag_ready = True


threading.Thread(target=_load_rag_background, daemon=True).start()


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
        url = "https://api.groq.com/openai/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {GROQ_API_KEY}",
            "Content-Type": "application/json",
        }
        res = requests.post(url, json=payload, headers=headers, timeout=15)
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


@app.route('/status', methods=['GET'])
@limiter.limit("60 per minute")
def status():
    with _rag_lock:
        ready = _rag_ready
    return jsonify({"ready": ready}), 200


@app.route('/chat', methods=['POST'])
@jwt_required()
@limiter.limit("30 per minute")
def chat():
    with _rag_lock:
        rag_ready = _rag_ready

    if not rag_ready:
        return jsonify({"error": "Le système démarre, merci de patienter quelques secondes et de réessayer."}), 503

    user_id = int(get_jwt_identity())
    data = request.get_json()
    if not data or 'message' not in data:
        return jsonify({"error": "Le champ 'message' est obligatoire"}), 400

    user_message = data['message']
    conv_id = data.get('conversation_id')
    stream_requested = data.get('stream', True)

    if conv_id:
        conv = Conversation.query.filter_by(id=conv_id, user_id=user_id).first()
        if not conv:
            return jsonify({"error": "Conversation introuvable"}), 404
    else:
        title = user_message[:60] + ("…" if len(user_message) > 60 else "")
        conv = Conversation(user_id=user_id, title=title)
        db.session.add(conv)
        db.session.commit()

    db.session.add(Message(conversation_id=conv.id, role='user', content=user_message))
    db.session.commit()

    raw_history = [
        {"role": m.role, "content": m.content}
        for m in conv.messages[:-1]
    ]
    history = raw_history[-MAX_HISTORY:]

    with _rag_lock:
        vs = vector_store

    context = ""
    fallback_used = False

    if vs:
        results = vs.similarity_search_with_score(user_message, k=10)
        relevant = [doc for doc, score in results if score < 2.0]

        # Fallback si peu de résultats pertinents ou mots-clés sensibles
        if len(relevant) < 3 or _should_use_fallback(user_message):
            print("[RAG] Fallback activé - chargement PDF complet")
            fallback_used = True
            full_context = ""
            for filename in os.listdir(PDF_FOLDER):
                if filename.lower().endswith(".pdf"):
                    full_text = _load_full_pdf(filename)
                    if full_text:
                        full_context += f"\n\n--- Document : {filename} ---\n{full_text}"

            if full_context:
                context = (
                    "Voici les informations complètes extraites des documents officiels :\n\n"
                    + full_context
                    + "\n\n---\nUtilise uniquement ces informations pour répondre de façon claire et structurée."
                )
            else:
                context = "Aucune information disponible dans les documents."
        else:
            raw_ctx = "\n\n".join(doc.page_content for doc in relevant)
            context = (
                "Voici les informations officielles disponibles pour répondre à cette question :\n\n"
                + raw_ctx
                + "\n\n---\nUtilise uniquement ces informations pour formuler ta réponse de façon naturelle et chaleureuse."
            )

    full_system_prompt = SYSTEM_PROMPT_BASE + "\n\n" + context

    payload = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": full_system_prompt},
            *history,
            {"role": "user", "content": user_message},
        ],
        "stream": stream_requested,
        "temperature": 0.2,
        "max_tokens": 1200,
    }

    url = "https://api.groq.com/openai/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {GROQ_API_KEY}",
        "Content-Type": "application/json",
    }

    try:
        resp = requests.post(url, json=payload, headers=headers, stream=stream_requested, timeout=90)

        if resp.status_code != 200:
            return jsonify({"error": f"Groq error {resp.status_code}"}), resp.status_code

        if not stream_requested:
            answer = resp.json()['choices'][0]['message']['content']
            with app.app_context():
                db.session.add(Message(conversation_id=conv.id, role='assistant', content=answer))
                db.session.execute(db.update(Conversation).where(Conversation.id == conv.id).values(updated_at=datetime.utcnow()))
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
                        db.session.add(Message(conversation_id=conv.id, role='assistant', content=full_answer))
                        db.session.execute(db.update(Conversation).where(Conversation.id == conv.id).values(updated_at=datetime.utcnow()))
                        db.session.commit()

                    if is_first_exchange:
                        threading.Thread(target=_generate_title, args=(conv.id, user_message, full_answer), daemon=True).start()

                    yield 'data: [DONE]\n\n'
                    break

                try:
                    parsed = json.loads(payload_str)
                    delta = parsed['choices'][0]['delta'].get('content', '')
                    if delta:
                        assistant_buffer.append(delta)
                except Exception:
                    pass

                yield decoded + '\n\n'

        return Response(generate(), mimetype='text/event-stream')

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": f"Erreur interne serveur: {str(e)}"}), 500


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000, use_reloader=False)