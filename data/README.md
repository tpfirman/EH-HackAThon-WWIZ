# Full Metal Productions - WWIZ Test Data

This directory contains comprehensive test data for **Full Metal Productions**, a YouTube company and independent game development firm.

## 🚀 Current Status: Ready for Milestone 2

This test dataset is prepared for **Milestone 2: Ingest Test Data and Test AI** to validate the WWIZ concept.

## 🏢 Company Overview

**Full Metal Productions** is a creative digital media company specializing in:
- 🎮 **Game Development**: 5 released games, 2 in production
- 🎬 **YouTube Content**: Gaming content and tutorials  
- ⛏️ **Minecraft Mods**: Extensive back catalog of popular mods
- 🎯 **Independent Development**: Small, agile team structure

## 👥 Employee Structure (52 Employees)

### Executive Team (3)
- **Tim Firman** - CEO (FMP001) 👑
- **Sarah Chen** - COO (FMP002)
- **Michael Rodriguez** - CFO (FMP003)

### Development Team (9)
- **Alex Thompson** - Lead Developer (FMP004)
- Senior Developers, Developers, Junior Developers, DevOps Engineer

### Game Design Team (5)
- **Jordan Martinez** - Game Director (FMP013)
- Senior Game Designers, Game Designers, Level Designer

### Art & Animation Team (8)
- **Maya Patel** - Art Director (FMP018)
- 3D Artists, 2D Artists, Animators, UI/UX Designer

### YouTube Content Team (6)
- **Emma Lewis** - Content Director (FMP026)
- Video Producers, Video Editors, Thumbnail Designer, Social Media Manager

### QA Team (4)
- **Charlotte Green** - QA Lead (FMP032)
- Senior QA Testers, QA Testers

### Support Teams (17)
- HR Team (2): **Amelia Nelson** - HR Director
- Finance Team (2): **Grace Roberts** - Finance Director  
- Marketing Team (3): **Lily Evans** - Marketing Director
- Operations Team (3): **Mason Collins** - Operations Manager

## 🎮 Projects & Games

### Released Games (5)
- **CyberRealm** (CYBR) - Futuristic action game
- **Shadow Ninja Chronicles** (NINJA) - Stealth adventure
- **Space Colony Builder** (SPACE) - Strategy simulation
- **Pixel Adventure Quest** (PIXEL) - Retro platformer
- **Tower Defense Ultimate** (TOWER) - Strategic defense

### Games in Production (2)
- **Fantasy Realm Online** (MMORPG) - Massive multiplayer RPG
- **Midnight Terror** (HORROR) - Psychological horror

### Minecraft Mods (4)
- **MC Tech Overhaul** (MCTECH) - Technology enhancement
- **MC Magic Systems** (MCMAG) - Magical gameplay elements
- **MC Advanced Building** (MCBUILD) - Construction tools
- **MC RPG Elements** (MCRPG) - Role-playing features

### Content Projects (2)
- **YouTube Channel** (YTCHAN) - Gaming content and tutorials
- **Live Streaming** (STREAM) - Interactive gaming sessions

## 📁 Data Structure

```
data/
├── employmentHero-staff/          # 52 employee records (FMP001-FMP052)
├── entraAd-user/                  # 52 Azure AD user records
├── googleCloudIdentity-user/      # 52 Google Workspace user records
├── jira-userStats/                # 35 Jira users (dev/design/art/qa/youtube/marketing)
├── jira-projectSummary/           # 11 project summaries
├── confluence-userStats/          # 50 Confluence users (most employees)
├── confluence-spacesSummary/      # 5 team spaces (DEV, DESIGN, ART, COMPANY, YOUTUBE)
├── calendar-availabilitySummary/  # 52 calendar records
├── teams-userActivitySummary/     # 52 Teams activity records
└── slack-userActivitySummary/     # 52 Slack activity records
```

## 🔗 Data Relationships

- **Primary Key**: `ehsId` (Format: FMP001-FMP052)
- **Email Domain**: `@fullmetalproductions.com`
- **Location**: Remote/Melbourne Office
- **Timezone**: Australia/Melbourne

## 📊 Access Patterns

### Jira Access (35 users)
- All Development, Game Design, Art & Animation, QA teams
- YouTube Content and Marketing teams
- Executive team (CEO, COO, CFO)

### Confluence Access (50 users)
- Nearly all employees (except some junior roles)
- 5 team spaces with realistic content and activity

### Communication Tools (52 users)
- **Microsoft Teams**: All employees
- **Slack**: All employees  
- **Calendar**: All employees with realistic availability

## 🎯 Use Cases for WWIZ

This dataset enables WWIZ to answer questions like:

**People Questions:**
- "Who is the lead developer?"
- "What team does Sarah Chen manage?"
- "Who has worked on the Fantasy Realm Online project?"

**Project Questions:**
- "What games has Full Metal Productions released?"
- "Which projects are currently in production?"
- "Who is working on the MMORPG project?"

**Availability Questions:**
- "Is Tim Firman available for a meeting?"
- "Who in the art team is currently online?"
- "What's Alex Thompson's current workload?"

**Company Structure:**
- "Who reports to Maya Patel?"
- "What departments does Full Metal Productions have?"
- "How long has Jessica Williams been with the company?"

## 🚀 AnythingLLM Integration

Files are optimized for AnythingLLM with:
- ✅ **Rich Context**: Names, roles, and relationships repeated for AI understanding
- ✅ **Structured JSON**: Easy parsing and semantic search
- ✅ **Realistic Data**: Authentic relationships and activity patterns
- ✅ **Comprehensive Coverage**: All aspects of company operations

## 📝 File Naming Convention

- **Employee Records**: `{ehsId}.json` (e.g., `FMP001.json` for Tim Firman)
- **Project Records**: `{projectKey}.json` (e.g., `MMORPG.json`)
- **Space Records**: `{spaceKey}.json` (e.g., `DEV.json`)

## 🔄 Data Freshness

- **Last Updated**: August 23, 2025
- **Data Source**: Generated test data
- **Update Frequency**: Static test dataset
- **Total Files**: 425 JSON files

---

*This test dataset provides a comprehensive foundation for demonstrating WWIZ's capabilities in a realistic company environment.*
