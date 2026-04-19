from flask import Blueprint, request, jsonify
from werkzeug.security import check_password_hash, generate_password_hash
from flask_jwt_extended import create_access_token
from db import db
from models.user import User
import requests

auth_bp = Blueprint('auth', __name__)

GOOGLE_CLIENT_ID = "524608439249-e0ifvgqdp2ekurqp3dj9fr3qu3rgsfog.apps.googleusercontent.com"


@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Corps de la requête manquant"}), 400

    name = data.get('name', '').strip()
    email = data.get('email', '').strip().lower()
    password = data.get('password', '')

    if not name or not email or not password or len(password) < 6:
        return jsonify({"error": "Données invalides"}), 400

    if User.query.filter_by(email=email).first():
        return jsonify({"error": "Cet email est déjà utilisé"}), 409

    new_user = User(
        name=name,
        email=email,
        password_hash=generate_password_hash(password),
        provider='email'
    )

    try:
        db.session.add(new_user)
        db.session.commit()
        return jsonify({"message": "Compte créé avec succès", "user": new_user.to_dict()}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Erreur lors de la création du compte : {str(e)}"}), 500


@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Corps de la requête manquant"}), 400

    email = data.get('email', '').strip().lower()
    password = data.get('password', '')

    if not email or not password:
        return jsonify({"error": "Email et mot de passe obligatoires"}), 400

    user = User.query.filter_by(email=email).first()

    if not user or user.provider == 'google' or not check_password_hash(user.password_hash or '', password):
        return jsonify({"error": "Email ou mot de passe incorrect"}), 401

    token = create_access_token(identity=str(user.id))

    return jsonify({"token": token, "user": user.to_dict()}), 200


@auth_bp.route('/google', methods=['POST'])
def google_login():
    data = request.get_json()
    if not data or 'id_token' not in data:
        return jsonify({"error": "Token Google manquant"}), 400

    id_token = data['id_token']

    try:
        response = requests.get(f"https://oauth2.googleapis.com/tokeninfo?id_token={id_token}")
        if response.status_code != 200:
            return jsonify({"error": "Token Google invalide"}), 401

        token_info = response.json()

        email = token_info.get('email')
        name = token_info.get('name', 'Utilisateur Google')
        google_id = token_info.get('sub')
        picture = token_info.get('picture')

        if not email:
            return jsonify({"error": "Email non fourni par Google"}), 400

        user = User.query.filter_by(email=email).first()

        if user:
            if not user.google_id:
                user.google_id = google_id
                user.provider = 'google'
                user.avatar_url = picture
                db.session.commit()
        else:
            user = User(
                name=name,
                email=email,
                google_id=google_id,
                provider='google',
                avatar_url=picture
            )
            db.session.add(user)
            db.session.commit()

        token = create_access_token(identity=str(user.id))

        return jsonify({"token": token, "user": user.to_dict()}), 200

    except Exception as e:
        return jsonify({"error": "Erreur lors de la vérification Google"}), 500