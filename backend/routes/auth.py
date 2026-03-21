from flask import Blueprint, request, jsonify
from werkzeug.security import generate_password_hash
from db import db
from models.user import User

auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/register', methods=['POST'])
def register():
    """
    Inscription d'un nouvel utilisateur
    ---
    tags:
      - Auth
    parameters:
      - name: body
        in: body
        required: true
        schema:
          type: object
          required:
            - name
            - email
            - password
          properties:
            name:
              type: string
              example: "Jean Dupont"
            email:
              type: string
              example: "jean@example.com"
            password:
              type: string
              example: "motdepasse123"
    responses:
      201:
        description: Utilisateur créé avec succès
        schema:
          type: object
          properties:
            message:
              type: string
            user:
              type: object
      400:
        description: Données manquantes ou invalides
      409:
        description: Email déjà utilisé
      500:
        description: Erreur serveur
    """
    data = request.get_json()


    if not data:
        return jsonify({"error": "Corps de la requête manquant"}), 400

    name = data.get('name', '').strip()
    email = data.get('email', '').strip().lower()
    password = data.get('password', '')

    if not name:
        return jsonify({"error": "Le champ 'name' est obligatoire"}), 400
    if not email:
        return jsonify({"error": "Le champ 'email' est obligatoire"}), 400
    if not password or len(password) < 6:
        return jsonify({"error": "Le mot de passe doit contenir au moins 6 caractères"}), 400


    existing = User.query.filter_by(email=email).first()
    if existing:
        return jsonify({"error": "Cet email est déjà utilisé"}), 409

    hashed_password = generate_password_hash(password)
    new_user = User(name=name, email=email, password_hash=hashed_password)

    try:
        db.session.add(new_user)
        db.session.commit()
        return jsonify({
            "message": "Compte créé avec succès",
            "user": new_user.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Erreur lors de la création du compte : {str(e)}"}), 500