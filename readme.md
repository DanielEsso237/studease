**StudEase – Faculty of Science Expert Chatbot**

Intelligent academic assistant for the Faculty of Science – University of Ebolowa  
Built with Flutter & FastAPI

**Overview**

   StudEase is an intelligent expert chatbot system designed to centralize and automate access to academic and administrative information for students of the Faculty of Science at the University of Ebolowa.

   The system aims to reduce administrative workload while providing students with fast, reliable, and centralized information access — available 24/7.

   This project was developed as a First Cycle Final Year Project and serves as both an academic submission and a professional portfolio project.

**Problem Statement**

   The Faculty of Science at the University of Ebolowa experiences:

   - High volume of repetitive student inquiries
   - Overloaded administrative staff
   - Scattered information sources (website, notice boards, offices, social media)
   - Long queues at the secretariat
   - Lack of centralized and updated information

   **Core Question**

   How can we provide fast, reliable, and centralized academic information access while reducing administrative burden?

**Objectives**

   **General Objective**

   Develop an intelligent expert chatbot capable of providing automated and reliable information about the Faculty of Science.

   **Specific Objectives**

   - Centralize faculty-related information
   - Automate responses to frequently asked questions
   - Assist academic orientation
   - Simplify administrative procedures
   - Improve communication between students and administration
   - Reduce administrative workload by 70–80%
   - Provide 24/7 availability
   - Build an extensible rule-based expert system

**Features**

   **1. FAQ Automation**

   - Registration & re-registration procedures
   - Academic calendar
   - Tuition fees
   - Secretariat contacts & office hours
   - Office and classroom locations

   **2. Intelligent Academic Orientation**

   - Available study programs
   - Prerequisites for each program
   - Career opportunities
   - Program comparisons
   - Personalized advice based on student profile

   **3. Administrative Guide**

   - Transcript request procedure
   - Complaint process
   - Validation & resit procedures
   - Internship/stage documentation
   - Defense calendar (if applicable)

   **4. Expert System Core**

   The chatbot integrates:

   - A structured knowledge base
   - Rule-based inference engine (if–then logic)
   - Reasoning system for complex cases

   Example:  
   “I am in 2nd year and failed 3 courses, what should I do?”  
   The system analyzes academic rules and provides the appropriate procedure.

   **5. Admin Dashboard**

   - Add/modify information
   - Add inference rules without coding
   - View most frequent questions
   - Usage statistics

   **6. Natural Conversation Mode**

   - Handles vague questions
   - Reformulates unclear queries
   - Provides direct access to PDFs and resources

   **7. Modern Interface**

   - Mobile & Desktop support
   - Dark mode
   - Clean UI

**Tech Stack**

   **Frontend**

   - Flutter

   **Backend**

   - FastAPI
   - Python
   - PostgreSQL Database
   - Rule-based inference engine

**Project Structure**

    studEase/
    │
    ├── frontend/        # Flutter application
    │
    ├── backend/         # FastAPI server & expert system
    │
    └── README.md

**Installation**

   **Clone the repository**

   - git clone https://github.com/DanielEsso237/studease
   - cd studEase

   **Backend setup**

   cd backend
   python -m venv venv
   source venv/bin/activate  # (or venv\Scripts\activate on Windows)
   pip install -r requirements.txt
   uvicorn main:app --reload

   **Frontend setup**

   cd frontend
   flutter pub get
   flutter run

**Future improvements**

   AI/NLP enhancement

   Voice assistant integration

**Academic context**

   This project was developed as a Final Year Project (First Cycle) for the Faculty of Science – University of Ebolowa
