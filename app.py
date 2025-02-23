from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_cors import CORS
import os
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Database configuration
app.config['SQLALCHEMY_DATABASE_URI'] = f"mysql+pymysql://{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}@{os.getenv('DB_HOST')}/mtb_survey"
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

class Survey(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    experience_years = db.Column(db.String(50))
    skill_level = db.Column(db.String(50))
    favorite_trail = db.Column(db.Text)
    submitted_at = db.Column(db.DateTime, default=datetime.utcnow)
    ip_address = db.Column(db.String(50))

# Create tables on startup
with app.app_context():
    db.create_all()

@app.route('/api/survey', methods=['POST'])
def submit_survey():
    data = request.json
    # Get real client IP from proxy headers
    client_ip = request.headers.get('X-Forwarded-For', request.headers.get('X-Real-IP', request.remote_addr))
    # If multiple IPs in X-Forwarded-For, get the first one (original client)
    if client_ip and ',' in client_ip:
        client_ip = client_ip.split(',')[0].strip()

    new_survey = Survey(
        experience_years=data['experience'],
        skill_level=data['skill_level'],
        favorite_trail=data['favorite_trail'],
        ip_address=client_ip
    )
    db.session.add(new_survey)
    db.session.commit()
    return jsonify({"message": "Survey submitted successfully"}), 201

@app.route('/api/surveys', methods=['GET'])
def get_surveys():
    surveys = Survey.query.all()
    return jsonify([{
        'id': s.id,
        'experience_years': s.experience_years,
        'skill_level': s.skill_level,
        'favorite_trail': s.favorite_trail,
        'submitted_at': s.submitted_at.isoformat(),
        'ip_address': s.ip_address
    } for s in surveys])

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000) 