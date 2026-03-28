from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from werkzeug.security import check_password_hash, generate_password_hash
from db import db
from models.user import User

account_bp = Blueprint('account', __name__)


@account_bp.route('/account', methods=['GET'])
@jwt_required()
def get_account():
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    if not user:
        return jsonify({"error": "Utilisateur introuvable"}), 404
    return jsonify(user.to_dict()), 200


@account_bp.route('/account/username', methods=['PUT'])
@jwt_required()
def update_username():
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    if not user:
        return jsonify({"error": "Utilisateur introuvable"}), 404

    data = request.get_json() or {}
    name = data.get('name', '').strip()

    if not name:
        return jsonify({"error": "Le nom est obligatoire"}), 400
    if len(name) < 2:
        return jsonify({"error": "Le nom doit contenir au moins 2 caractères"}), 400

    user.name = name
    db.session.commit()

    return jsonify(user.to_dict()), 200


@account_bp.route('/account/password', methods=['PUT'])
@jwt_required()
def update_password():
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    if not user:
        return jsonify({"error": "Utilisateur introuvable"}), 404

    data = request.get_json() or {}
    current_password = data.get('current_password', '')
    new_password     = data.get('new_password', '')

    if not current_password or not new_password:
        return jsonify({"error": "Les deux mots de passe sont obligatoires"}), 400

    if not check_password_hash(user.password_hash, current_password):
        return jsonify({"error": "Mot de passe actuel incorrect"}), 401

    if len(new_password) < 6:
        return jsonify({"error": "Le nouveau mot de passe doit contenir au moins 6 caractères"}), 400

    if current_password == new_password:
        return jsonify({"error": "Le nouveau mot de passe doit être différent de l'ancien"}), 400

    user.password_hash = generate_password_hash(new_password)
    db.session.commit()

    return jsonify({"message": "Mot de passe mis à jour avec succès"}), 200


@account_bp.route('/account', methods=['DELETE'])
@jwt_required()
def delete_account():
    user_id = int(get_jwt_identity())
    user = User.query.get(user_id)
    if not user:
        return jsonify({"error": "Utilisateur introuvable"}), 404

    data = request.get_json() or {}
    password = data.get('password', '')

    if not check_password_hash(user.password_hash, password):
        return jsonify({"error": "Mot de passe incorrect"}), 401

    db.session.delete(user)
    db.session.commit()

    return jsonify({"message": "Compte supprimé avec succès"}), 200