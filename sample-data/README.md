# WWIZ Data Structure

This directory contains the organized data structure for the WWIZ (Who's Who in the Zoo) AI knowledge base.

## � Status: Template Structure for Milestone 3

This structure provides the framework for **Milestone 3: Automation** when implementing data ingest scripts.

## �📁 Folder Structure

Each object type has its own folder containing template files and actual data files:

```
data/
├── employmentHero-staff/          # Primary employee records (source of truth for ehsId)
├── entraAd-user/                  # Azure AD user information
├── googleCloudIdentity-user/      # Google Workspace user information  
├── jira-userStats/                # Individual Jira user activity and project data
├── jira-projectSummary/           # Project-level Jira information
├── confluence-userStats/          # Individual Confluence user activity
├── confluence-spacesSummary/      # Confluence space and content information
├── calendar-availabilitySummary/  # User calendar and availability data
├── teams-userActivitySummary/     # Microsoft Teams user activity
└── slack-userActivitySummary/     # Slack user activity
```

## 🔗 Data Relationships

- **Primary Key**: `ehsId` from `employmentHero-staff` is the linking identifier across all user-related objects
- **Data Redundancy**: Names, positions, and other key identifiers are repeated across files for AI efficiency
- **Individual Files**: Each person/project gets their own file within the appropriate folder

## 📄 File Format

**JSON** format is used for all data files because:
- ✅ Easy Python parsing with `json` module
- ✅ Structured data that LLMs understand well
- ✅ Compact file size
- ✅ Easy validation and maintenance
- ✅ Human-readable for debugging

## 📝 File Naming Convention

- User files: `{ehsId}.json` (e.g., `EHS001234.json`)
- Project files: `{projectKey}.json` (e.g., `PLAT.json`)
- Space files: `{spaceKey}.json` (e.g., `ENG.json`)

## 🔄 Update Process

1. Python scripts extract data from source systems
2. Data is transformed to match template structure
3. Files are written/updated in appropriate folders
4. AnythingLLM workspace ingests updated files
5. Embeddings are refreshed for AI agent

## 🛠️ Sample Files

Each folder contains a `sample.json` file showing the expected structure and sample data for that object type.

## 📊 Data Sources

- **employmentHero-staff**: Employment Hero HR system
- **entraAd-user**: Microsoft Azure Active Directory
- **googleCloudIdentity-user**: Google Workspace Admin
- **jira-userStats**: Atlassian Jira API
- **jira-projectSummary**: Atlassian Jira API
- **confluence-userStats**: Atlassian Confluence API
- **confluence-spacesSummary**: Atlassian Confluence API
- **calendar-availabilitySummary**: Microsoft Graph API (Calendar)
- **teams-userActivitySummary**: Microsoft Graph API (Teams)
- **slack-userActivitySummary**: Slack API

## 🚀 AnythingLLM Integration

Files are designed to be:
- Easily ingested by AnythingLLM document processors
- Efficiently embedded for semantic search
- Readable by AI agents with clear context and structure
- Updated incrementally without full knowledge base rebuilds
