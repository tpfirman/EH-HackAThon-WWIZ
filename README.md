# E### 💼 Mission Brief
Employment Hero's mission is to make employment easier and more valuable for everyone. 

You'll have 48 hours to create an AI-powered solution that reimagines any part of the work experience.

That's it. No limits. No prescribed path. Just your creativity, speed and execution.

We're looking for bold ideas that challenge the status quo. Need inspiration? Consider...

- ⚡ Workflows that automate HR processes and free people for meaningful work
- 🤖 An AI model that predicts workforce needs, boosts productivity, or detects burnout
- ❤️‍🩹 Smart systems that enhance employee wellbeing at scale
- 🧞 Or something so groundbreaking, we've never thought of it!

Big or small, if it can revolutionize work, we want to see it.WIZ

# EH-HackAThon-WWIZ

> An AI-powered workplace knowledge assistant that helps employees quickly find information about people, projects, and processes in their organization.

## 📋 Table of Contents
- [E### 💼 Mission Brief](#e--mission-brief)
- [EH-HackAThon-WWIZ](#eh-hackathon-wwiz)
  - [📋 Table of Contents](#-table-of-contents)
    - [🧑‍⚖️ Judging Criteria](#️-judging-criteria)
  - [My Solution](#my-solution)
    - [🏗️ Architecture](#️-architecture)
    - [📋 Plan of Attack](#-plan-of-attack)
      - [Milestone 1 - Basics](#milestone-1---basics)
      - [Milestone 2 - Automation](#milestone-2---automation)
      - [Milestone 3 - Documentation and Presentation](#milestone-3---documentation-and-presentation)
  - [🚀 Getting Started](#-getting-started)
  - [📝 Notes](#-notes)

You’ll have 48 hours to create an AI-powered solution that reimagines any part of the work experience.

That’s it. No limits. No prescribed path. Just your creativity, speed and execution.
We’re looking for bold ideas that challenge the status quo. 
Need inspiration? Consider...
•	⚡Workflows that automate HR processes and free people for meaningful work.
•	🤖 An AI model that predicts workforce needs, boosts productivity, or detects burnout.
•	❤️‍🩹 Smart systems that enhance employee wellbeing at scale.
•	🧞 Or something so groundbreaking, we’ve never thought of it!
Big or small, if it can revolutionise work, we want to see it.

### 🧑‍⚖️ Judging Criteria
Your submission will be evaluated on:

- **Innovation** – How original and creative is your idea? Does it challenge the status quo?
- **Impact** – Can it meaningfully improve how people work?
- **AI Proficiency** – Is the AI thoughtfully applied and technically sound?
- **User Value** – Is the concept intuitive and easy to see value in?
- **Execution** – Communication & pitching skills. Can we understand what it is, why it matters, and how it works?


## My Solution

**WWIZ (Who's Who in the Zoo)**

Everyone has been in a situation at work where they were wondering "Who do I talk to about that thing?", or heard about a project in a meeting and thought "Wait, what's that?", or seen a name on an email and wondered "Who is that?".

That's where WWIZ comes from. An AI Agent that has access to a dataset of properly formatted and scoped data around the company, its employees, current projects, events, and anything else deemed relevant.

Information is gathered from multiple sources, parsed and formatted to build a dataset that can be quickly accessed to provide accurate responses.

The AI Agent at no stage will have direct access to any sensitive systems. Instead, a collection of scripted scheduled and triggered tasks are used to query, format and store the data, before making it available to the chat agent.

### 🏗️ Architecture
*Work in Progress*

- **Hosting**: AWS for Compute and frontend
- **LLM**: AWS Bedrock, most likely using Nova
- **Frontend**: AnythingLLM is pre-built and works well for this use case
- **SSL/TLS**: Nginx reverse proxy with automatic HTTPS redirect
- **Certificates**: Let's Encrypt for production, self-signed for development
- **Data Store**: On EC2 native storage for now. Will move to S3 if possible
- **Data Aggregation**: A collection of Python scripts

#### Security Features
- Automatic HTTP to HTTPS redirect
- Modern TLS configuration (TLS 1.2/1.3)
- Security headers (HSTS, X-Frame-Options, etc.)
- Automatic certificate renewal

### 📋 Plan of Attack
#### Milestone 1 - Basics

1. **Get AWS resources up and running**
   - EC2 instance with Docker and AnythingLLM
   - Network infrastructure and supporting infrastructure running
   - Able to log into AnythingLLM frontend and talk to Nova

2. **AnythingLLM setup**
   - Create workspace for agent
   - Build out system prompts and agent settings tuning
   - Test user accounts ready
  
3. **Create and ingest test data**
   - Create data template for each intended source
   - Create test dataset
   - Upload and embed in agent

4. **Test Milestone 1**
   - Can I ask the agent questions relating to the test data and get an accurate and meaningful response?

#### Milestone 2 - Automation

5. **Create data ingest scripts**
   
6. **Create Python data parsing**
   - Create common handler for standard tasks
   - Create Python modules for each intended data source with a data class structure
   - Create Python script to extract and parse data and store ready for ingest

7. **Test Milestone 2**
   - Sign up for a bunch of trials and see how many I can pull data from

#### Milestone 3 - Documentation and Presentation

8. **Documentation**
   - Required documentation for submission
   - Standard product documentation
   - Identified risks
   - Any known issues
   - Anything that was planned but ran out of time for

9. **Video pitch**

10. **Get some sleep before work on Monday!** 😴

---

## 🚀 Getting Started

### Prerequisites
- Docker and Docker Compose installed
- Domain name pointing to your server (for production)

### Quick Start with HTTPS

1. **Clone the repository**
   ```bash
   git clone https://github.com/tpfirman/EH-HackAThon-WWIZ.git
   cd EH-HackAThon-WWIZ
   ```

2. **Set up HTTPS (Development)**
   ```bash
   # For local development with self-signed certificates
   ./setup-https.sh
   ```

3. **Set up HTTPS (Production)**
   ```bash
   # Copy and configure environment
   cp .env.example .env
   # Edit .env with your domain and email
   
   # Get real SSL certificate from Let's Encrypt
   DOMAIN=your-domain.com EMAIL=your-email@example.com ./scripts/get-letsencrypt-cert.sh
   ```

4. **Verify deployment**
   ```bash
   ./scripts/health-check.sh
   ```

### Access Your Application
- **Development**: https://wwiz.local (accept self-signed certificate)
- **Production**: https://your-domain.com

### SSL Certificate Management
- Certificates auto-renew via the certbot container
- Self-signed certificates are generated for development
- Production uses Let's Encrypt for free, trusted certificates

## 📝 Notes

- This project is being developed as part of Employment Hero's 48-hour hackathon
- Focus is on rapid prototyping and proof of concept
- Security and scalability considerations will be addressed in future iterations