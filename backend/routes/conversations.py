from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from db import db
from models.conversation import Conversation
from models.message import Message

conv_bp = Blueprint('conversations', __name__)


@conv_bp.route('/conversations', methods=['GET'])
@jwt_required()
def list_conversations():
    user_id = int(get_jwt_identity())
    convs = (Conversation.query
             .filter_by(user_id=user_id)
             .order_by(Conversation.updated_at.desc())
             .all())
    return jsonify([c.to_dict() for c in convs]), 200


@conv_bp.route('/conversations', methods=['POST'])
@jwt_required()
def create_conversation():
    user_id = int(get_jwt_identity())
    data    = request.get_json() or {}
    title   = data.get('title', 'Nouvelle conversation')
    conv    = Conversation(user_id=user_id, title=title)
    db.session.add(conv)
    db.session.commit()
    return jsonify(conv.to_dict()), 201



@conv_bp.route('/conversations/delete-all', methods=['DELETE'])
@jwt_required()
def delete_all_conversations():
    user_id = int(get_jwt_identity())
    try:
        convs = Conversation.query.filter_by(user_id=user_id).all()
        count = len(convs)
        for conv in convs:
            db.session.delete(conv)
        db.session.commit()
        return jsonify({
            "message": f"{count} conversation(s) supprimée(s) avec succès"
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Erreur lors de la suppression : {str(e)}"}), 500


@conv_bp.route('/conversations/<int:conv_id>/messages', methods=['GET'])
@jwt_required()
def get_messages(conv_id):
    user_id = int(get_jwt_identity())
    conv = Conversation.query.filter_by(id=conv_id, user_id=user_id).first()
    if not conv:
        return jsonify({"error": "Conversation introuvable"}), 404
    return jsonify([m.to_dict() for m in conv.messages]), 200


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


@conv_bp.route('/conversations/<int:conv_id>/title', methods=['PUT'])
@jwt_required()
def rename_conversation(conv_id):
    user_id = int(get_jwt_identity())
    conv = Conversation.query.filter_by(id=conv_id, user_id=user_id).first()
    if not conv:
        return jsonify({"error": "Conversation introuvable"}), 404

    data  = request.get_json() or {}
    title = data.get('title', '').strip()

    if not title:
        return jsonify({"error": "Le titre est obligatoire"}), 400
    if len(title) > 100:
        return jsonify({"error": "Titre trop long (100 caractères max)"}), 400

    conv.title = title
    db.session.commit()
    return jsonify(conv.to_dict()), 200