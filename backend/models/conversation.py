from datetime import datetime
from db import db

class Conversation(db.Model):
    __tablename__ = 'conversations'

    id         = db.Column(db.Integer, primary_key=True)
    user_id    = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    title      = db.Column(db.String(255), default="Nouvelle conversation")
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    messages = db.relationship('Message', backref='conversation',
                               lazy=True, cascade="all, delete-orphan",
                               order_by="Message.created_at")

    def to_dict(self):
        return {
            "id":         self.id,
            "title":      self.title,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
        }