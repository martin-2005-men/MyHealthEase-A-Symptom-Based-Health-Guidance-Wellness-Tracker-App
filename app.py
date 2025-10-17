from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import os

# ==============================
# 1️⃣ Initialize Flask App
# ==============================
app = Flask(__name__)
# Allows the Flutter client to make requests without cross-origin errors
CORS(app) 

# ==============================
# 2️⃣ Load the dataset (CRITICAL FIX)
# ==============================
# 💡 FIX: Use the correct CSV file path and the read_csv function
DATA_PATH = "health_conditions_dataset.xlsx"

df = None
vectorizer = None
symptom_vectors = None

try:
    # Use read_csv for the available file
    df = pd.read_excel(DATA_PATH) 
    
    # Preprocessing
    symptom_texts = df['symptoms'].astype(str)
    
    # TF-IDF vectorizer for symptoms
    vectorizer = TfidfVectorizer(stop_words='english')
    symptom_vectors = vectorizer.fit_transform(symptom_texts)
    
    print(f"✅ Data loaded successfully. Total entries: {len(df)}")
    
except FileNotFoundError:
    # Handle the error if the file is missing
    print(f"❌ ERROR: Data file not found at {DATA_PATH}. Please ensure the file is in the same directory as app.py.")
    print("The API endpoints will not function without the data.")

except KeyError as e:
    # Handle missing column error (e.g., if 'symptoms' column is missing)
    print(f"❌ ERROR: Missing required column {e} in the dataset. Check the CSV header structure.")
    
# ==============================
# 3️⃣ Home Route
# ==============================
@app.route('/', methods=['GET'])
def home():
    status = "running" if df is not None else "data load failed"
    return jsonify({
        "message": f"Health Condition API is {status} 🚀",
        "usage": {
            "endpoint": "/predict",
            "method": "POST",
            "body_format": {"symptoms": "string"}
        }
    })

# ==============================
# 4️⃣ Predict Route
# ==============================
@app.route('/predict', methods=['POST'])
def predict_condition():
    # Check if data loading was successful before proceeding
    if df is None or vectorizer is None or symptom_vectors is None:
        return jsonify({"error": "Server is running but failed to load the necessary health data."}), 500

    data = request.get_json()
    if not data or 'symptoms' not in data:
        return jsonify({"error": "Please provide 'symptoms' in JSON body"}), 400

    user_input = data['symptoms']
    if not user_input or user_input.strip() == "":
        return jsonify({"error": "Symptom input cannot be empty."}), 400

    user_vec = vectorizer.transform([user_input])
    sim_scores = cosine_similarity(user_vec, symptom_vectors).flatten()
    
    # Get the indices of the top 5 results
    top_indices = sim_scores.argsort()[-5:][::-1]
    
    results = []
    for i in top_indices:
        score = float(sim_scores[i])
        # Optional: Only return results with a minimum similarity score (e.g., above 0.1)
        if score > 0.05:
            results.append({
                # Ensure all fields are handled gracefully even if the column is NaN
                "health_condition": df.iloc[i]["health_condition"],
                "doctor_specialist": df.iloc[i]["doctor_specialist"],
                "diet_recommendations": df.iloc[i]["diet_recommendations"],
                "foods_to_avoid": df.iloc[i]["foods_to_avoid"],
                "diet_routine": df.iloc[i]["diet_routine"],
                "matched_symptoms": df.iloc[i]["symptoms"],
                "similarity_score": score
            })
    
    return jsonify({
        "input_symptoms": user_input,
        "results": results
    })

# ==============================
# 5️⃣ Run Flask
# ==============================
if __name__ == '__main__':
    # 💡 IMPORTANT: Run on '0.0.0.0' to ensure accessibility from clients like 
    # the Android Emulator (using 10.0.2.2) and the web preview (using 127.0.0.1).
    app.run(host='0.0.0.0', port=5000)
