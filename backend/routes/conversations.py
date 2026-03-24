from flask import Blueprint, request, jsonify, Response
from flask_jwt_extended import jwt_required, get_jwt_identity
import requests, os, json
from db import db
from models.conversation import Conversation
from models.message import Message

conv_bp = Blueprint('conversations', __name__)

# ── Lister les conversations de l'utilisateur ──────────────────────────────
@conv_bp.route('/conversations', methods=['GET'])
@jwt_required()
def list_conversations():
    user_id = int(get_jwt_identity())
    convs = (Conversation.query
             .filter_by(user_id=user_id)
             .order_by(Conversation.updated_at.desc())
             .all())
    return jsonify([c.to_dict() for c in convs]), 200


# ── Créer une nouvelle conversation ───────────────────────────────────────
@conv_bp.route('/conversations', methods=['POST'])
@jwt_required()
def create_conversation():
    user_id = int(get_jwt_identity())
    data    = request.get_json() or {}
    title   = data.get('title', 'Nouvelle conversation')

    conv = Conversation(user_id=user_id, title=title)
    db.session.add(conv)
    db.session.commit()
    return jsonify(conv.to_dict()), 201


# ── Charger les messages d'une conversation ────────────────────────────────
@conv_bp.route('/conversations/<int:conv_id>/messages', methods=['GET'])
@jwt_required()
def get_messages(conv_id):
    user_id = int(get_jwt_identity())
    conv = Conversation.query.filter_by(id=conv_id, user_id=user_id).first()
    if not conv:
        return jsonify({"error": "Conversation introuvable"}), 404
    return jsonify([m.to_dict() for m in conv.messages]), 200


# ── Supprimer une conversation ─────────────────────────────────────────────
@conv_bp.route('/conversations/<int:conv_id>', methods=['DELETE'])
@jwt_required()
def delete_conversation(conv_id):
    user_id = int(get_jwt_identity())
    conv = Conversation.query.filter_by(id=conv_id, user_id=user_id).first()
    if not conv:
        return jsonify({"error": "Conversation introuvable"}), 404
    db.session.delete(conv)
    db.session.commit()
    return jsonify({"message": "Supprimée"}), 200