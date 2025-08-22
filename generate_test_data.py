#!/usr/bin/env python3
"""
Generate test data for Full Metal Productions - WWIZ Knowledge Base
Creates realistic employee data across all data types for 50 employees.
"""

import json
import os
from datetime import datetime, timedelta
import random

# Company structure for Full Metal Productions
COMPANY_NAME = "Full Metal Productions"
COMPANY_DOMAIN = "fullmetalproductions.com"

# Department structure
DEPARTMENTS = {
    "Executive": ["CEO", "COO", "CFO"],
    "Development": ["Lead Developer", "Senior Developer", "Developer", "Junior Developer", "DevOps Engineer"],
    "Game Design": ["Game Director", "Senior Game Designer", "Game Designer", "Level Designer"],
    "Art & Animation": ["Art Director", "Senior Artist", "3D Artist", "2D Artist", "Animator", "UI/UX Designer"],
    "YouTube Content": ["Content Director", "Video Producer", "Video Editor", "Thumbnail Designer", "Social Media Manager"],
    "QA": ["QA Lead", "Senior QA Tester", "QA Tester"],
    "HR": ["HR Director", "HR Coordinator"],
    "Finance": ["Finance Director", "Accountant"],
    "Marketing": ["Marketing Director", "Community Manager", "Marketing Coordinator"],
    "Operations": ["Operations Manager", "IT Support", "Office Manager"]
}

# Projects structure
PROJECTS = {
    # Released Games
    "CYBR": {"name": "CyberRealm", "status": "released", "type": "game"},
    "NINJA": {"name": "Shadow Ninja Chronicles", "status": "released", "type": "game"},
    "SPACE": {"name": "Space Colony Builder", "status": "released", "type": "game"},
    "PIXEL": {"name": "Pixel Adventure Quest", "status": "released", "type": "game"},
    "TOWER": {"name": "Tower Defense Ultimate", "status": "released", "type": "game"},
    
    # In Production
    "MMORPG": {"name": "Fantasy Realm Online", "status": "in_production", "type": "game"},
    "HORROR": {"name": "Midnight Terror", "status": "in_production", "type": "game"},
    
    # Minecraft Mods
    "MCTECH": {"name": "MC Tech Overhaul", "status": "released", "type": "minecraft_mod"},
    "MCMAG": {"name": "MC Magic Systems", "status": "released", "type": "minecraft_mod"},
    "MCBUILD": {"name": "MC Advanced Building", "status": "released", "type": "minecraft_mod"},
    "MCRPG": {"name": "MC RPG Elements", "status": "released", "type": "minecraft_mod"},
    
    # YouTube Content
    "YTCHAN": {"name": "YouTube Channel", "status": "ongoing", "type": "content"},
    "STREAM": {"name": "Live Streaming", "status": "ongoing", "type": "content"}
}

# Employee data
EMPLOYEES = [
    # Executive
    {"firstName": "Tim", "lastName": "Firman", "position": "CEO", "department": "Executive", "manager": None, "startDate": "2020-01-01"},
    {"firstName": "Sarah", "lastName": "Chen", "position": "COO", "department": "Executive", "manager": "Tim Firman", "startDate": "2020-02-15"},
    {"firstName": "Michael", "lastName": "Rodriguez", "position": "CFO", "department": "Executive", "manager": "Tim Firman", "startDate": "2020-03-01"},
    
    # Development Team
    {"firstName": "Alex", "lastName": "Thompson", "position": "Lead Developer", "department": "Development", "manager": "Sarah Chen", "startDate": "2020-04-01"},
    {"firstName": "Emily", "lastName": "Johnson", "position": "Senior Developer", "department": "Development", "manager": "Alex Thompson", "startDate": "2020-06-15"},
    {"firstName": "David", "lastName": "Kim", "position": "Senior Developer", "department": "Development", "manager": "Alex Thompson", "startDate": "2020-08-01"},
    {"firstName": "Jessica", "lastName": "Williams", "position": "Developer", "department": "Development", "manager": "Alex Thompson", "startDate": "2021-01-15"},
    {"firstName": "Ryan", "lastName": "O'Connor", "position": "Developer", "department": "Development", "manager": "Alex Thompson", "startDate": "2021-03-01"},
    {"firstName": "Lisa", "lastName": "Zhang", "position": "Developer", "department": "Development", "manager": "Alex Thompson", "startDate": "2021-05-15"},
    {"firstName": "James", "lastName": "Brown", "position": "Junior Developer", "department": "Development", "manager": "Alex Thompson", "startDate": "2022-01-15"},
    {"firstName": "Amy", "lastName": "Davis", "position": "Junior Developer", "department": "Development", "manager": "Alex Thompson", "startDate": "2022-06-01"},
    {"firstName": "Mark", "lastName": "Wilson", "position": "DevOps Engineer", "department": "Development", "manager": "Alex Thompson", "startDate": "2021-09-01"},
    
    # Game Design Team
    {"firstName": "Jordan", "lastName": "Martinez", "position": "Game Director", "department": "Game Design", "manager": "Sarah Chen", "startDate": "2020-05-01"},
    {"firstName": "Samantha", "lastName": "Lee", "position": "Senior Game Designer", "department": "Game Design", "manager": "Jordan Martinez", "startDate": "2020-07-15"},
    {"firstName": "Chris", "lastName": "Anderson", "position": "Game Designer", "department": "Game Design", "manager": "Jordan Martinez", "startDate": "2021-02-01"},
    {"firstName": "Rachel", "lastName": "Taylor", "position": "Game Designer", "department": "Game Design", "manager": "Jordan Martinez", "startDate": "2021-08-15"},
    {"firstName": "Kevin", "lastName": "Moore", "position": "Level Designer", "department": "Game Design", "manager": "Jordan Martinez", "startDate": "2022-03-01"},
    
    # Art & Animation Team
    {"firstName": "Maya", "lastName": "Patel", "position": "Art Director", "department": "Art & Animation", "manager": "Sarah Chen", "startDate": "2020-04-15"},
    {"firstName": "Lucas", "lastName": "Garcia", "position": "Senior Artist", "department": "Art & Animation", "manager": "Maya Patel", "startDate": "2020-09-01"},
    {"firstName": "Zoe", "lastName": "Mitchell", "position": "3D Artist", "department": "Art & Animation", "manager": "Maya Patel", "startDate": "2021-01-01"},
    {"firstName": "Nathan", "lastName": "Cooper", "position": "3D Artist", "department": "Art & Animation", "manager": "Maya Patel", "startDate": "2021-07-01"},
    {"firstName": "Isabella", "lastName": "White", "position": "2D Artist", "department": "Art & Animation", "manager": "Maya Patel", "startDate": "2021-04-15"},
    {"firstName": "Ethan", "lastName": "Hall", "position": "2D Artist", "department": "Art & Animation", "manager": "Maya Patel", "startDate": "2022-02-01"},
    {"firstName": "Sophia", "lastName": "Young", "position": "Animator", "department": "Art & Animation", "manager": "Maya Patel", "startDate": "2021-10-01"},
    {"firstName": "Oliver", "lastName": "Clark", "position": "UI/UX Designer", "department": "Art & Animation", "manager": "Maya Patel", "startDate": "2021-12-01"},
    
    # YouTube Content Team
    {"firstName": "Emma", "lastName": "Lewis", "position": "Content Director", "department": "YouTube Content", "manager": "Sarah Chen", "startDate": "2020-06-01"},
    {"firstName": "Liam", "lastName": "Walker", "position": "Video Producer", "department": "YouTube Content", "manager": "Emma Lewis", "startDate": "2020-10-01"},
    {"firstName": "Ava", "lastName": "Allen", "position": "Video Editor", "department": "YouTube Content", "manager": "Emma Lewis", "startDate": "2021-01-15"},
    {"firstName": "Noah", "lastName": "Wright", "position": "Video Editor", "department": "YouTube Content", "manager": "Emma Lewis", "startDate": "2021-06-01"},
    {"firstName": "Mia", "lastName": "Lopez", "position": "Thumbnail Designer", "department": "YouTube Content", "manager": "Emma Lewis", "startDate": "2022-01-01"},
    {"firstName": "William", "lastName": "Hill", "position": "Social Media Manager", "department": "YouTube Content", "manager": "Emma Lewis", "startDate": "2021-09-15"},
    
    # QA Team
    {"firstName": "Charlotte", "lastName": "Green", "position": "QA Lead", "department": "QA", "manager": "Alex Thompson", "startDate": "2020-11-01"},
    {"firstName": "Benjamin", "lastName": "Adams", "position": "Senior QA Tester", "department": "QA", "manager": "Charlotte Green", "startDate": "2021-03-15"},
    {"firstName": "Harper", "lastName": "Baker", "position": "QA Tester", "department": "QA", "manager": "Charlotte Green", "startDate": "2021-08-01"},
    {"firstName": "Logan", "lastName": "Gonzalez", "position": "QA Tester", "department": "QA", "manager": "Charlotte Green", "startDate": "2022-04-01"},
    
    # HR Team
    {"firstName": "Amelia", "lastName": "Nelson", "position": "HR Director", "department": "HR", "manager": "Tim Firman", "startDate": "2020-05-15"},
    {"firstName": "Elijah", "lastName": "Carter", "position": "HR Coordinator", "department": "HR", "manager": "Amelia Nelson", "startDate": "2021-11-01"},
    
    # Finance Team
    {"firstName": "Grace", "lastName": "Roberts", "position": "Finance Director", "department": "Finance", "manager": "Michael Rodriguez", "startDate": "2020-07-01"},
    {"firstName": "Henry", "lastName": "Phillips", "position": "Accountant", "department": "Finance", "manager": "Grace Roberts", "startDate": "2021-05-01"},
    
    # Marketing Team
    {"firstName": "Lily", "lastName": "Evans", "position": "Marketing Director", "department": "Marketing", "manager": "Sarah Chen", "startDate": "2020-08-15"},
    {"firstName": "Jackson", "lastName": "Turner", "position": "Community Manager", "department": "Marketing", "manager": "Lily Evans", "startDate": "2021-02-15"},
    {"firstName": "Chloe", "lastName": "Parker", "position": "Marketing Coordinator", "department": "Marketing", "manager": "Lily Evans", "startDate": "2021-10-15"},
    
    # Operations Team
    {"firstName": "Mason", "lastName": "Collins", "position": "Operations Manager", "department": "Operations", "manager": "Sarah Chen", "startDate": "2020-09-01"},
    {"firstName": "Avery", "lastName": "Edwards", "position": "IT Support", "department": "Operations", "manager": "Mason Collins", "startDate": "2021-04-01"},
    {"firstName": "Evelyn", "lastName": "Stewart", "position": "Office Manager", "department": "Operations", "manager": "Mason Collins", "startDate": "2020-12-01"},
    
    # Additional employees to reach 50
    {"firstName": "Sebastian", "lastName": "Sanchez", "position": "Developer", "department": "Development", "manager": "Alex Thompson", "startDate": "2022-07-01"},
    {"firstName": "Luna", "lastName": "Morris", "position": "QA Tester", "department": "QA", "manager": "Charlotte Green", "startDate": "2022-08-01"},
    {"firstName": "Grayson", "lastName": "Rogers", "position": "3D Artist", "department": "Art & Animation", "manager": "Maya Patel", "startDate": "2022-09-01"},
    {"firstName": "Scarlett", "lastName": "Reed", "position": "Video Editor", "department": "YouTube Content", "manager": "Emma Lewis", "startDate": "2022-10-01"},
    {"firstName": "Leo", "lastName": "Cook", "position": "Junior Developer", "department": "Development", "manager": "Alex Thompson", "startDate": "2023-01-15"},
    {"firstName": "Hazel", "lastName": "Bell", "position": "Game Designer", "department": "Game Design", "manager": "Jordan Martinez", "startDate": "2023-03-01"},
    {"firstName": "Caleb", "lastName": "Murphy", "position": "2D Artist", "department": "Art & Animation", "manager": "Maya Patel", "startDate": "2023-05-01"}
]

def calculate_length_of_service(start_date_str):
    """Calculate length of service from start date."""
    start_date = datetime.strptime(start_date_str, "%Y-%m-%d")
    current_date = datetime(2025, 8, 23)
    diff = current_date - start_date
    
    years = diff.days // 365
    months = (diff.days % 365) // 30
    
    if years > 0:
        return f"{years} year{'s' if years != 1 else ''} {months} month{'s' if months != 1 else ''}"
    else:
        return f"{months} month{'s' if months != 1 else ''}"

def generate_ehs_id(index):
    """Generate Employment Hero Staff ID."""
    return f"FMP{index:03d}"

def generate_email(first_name, last_name):
    """Generate company email address."""
    return f"{first_name.lower()}.{last_name.lower()}@{COMPANY_DOMAIN}"

def has_jira_access(department, position):
    """Determine if employee should have Jira access based on role."""
    jira_departments = ["Development", "Game Design", "Art & Animation", "QA", "YouTube Content", "Marketing"]
    executive_positions = ["CEO", "COO", "CFO"]
    
    return department in jira_departments or position in executive_positions

def has_confluence_access(department, position):
    """Determine if employee should have Confluence access."""
    # Most employees have Confluence access except some junior roles
    excluded_positions = []  # Everyone gets Confluence for now
    return position not in excluded_positions

def generate_employee_data():
    """Generate all employee data files."""
    
    data_dir = "c:/git/EH-HackAThon-WWIZ/data"
    
    for i, employee in enumerate(EMPLOYEES):
        ehs_id = generate_ehs_id(i + 1)
        email = generate_email(employee["firstName"], employee["lastName"])
        upn = email
        
        # Employment Hero Staff record
        eh_data = {
            "ehsId": ehs_id,
            "firstName": employee["firstName"],
            "lastName": employee["lastName"],
            "positionTitle": employee["position"],
            "team": employee["department"],
            "manager": employee["manager"],
            "lengthOfService": calculate_length_of_service(employee["startDate"]),
            "startDate": employee["startDate"],
            "department": employee["department"],
            "location": "Remote/Melbourne Office",
            "employmentType": "Full-time",
            "lastUpdated": "2025-08-23T10:30:00Z",
            "dataSource": "employmentHero-staff"
        }
        
        with open(f"{data_dir}/employmentHero-staff/{ehs_id}.json", "w") as f:
            json.dump(eh_data, f, indent=2)
        
        # Entra AD User record
        entra_data = {
            "ehsId": ehs_id,
            "firstName": employee["firstName"],
            "lastName": employee["lastName"],
            "email": email,
            "upn": upn,
            "displayName": f"{employee['firstName']} {employee['lastName']}",
            "jobTitle": employee["position"],
            "department": employee["department"],
            "officeLocation": "Melbourne/Remote",
            "mobilePhone": f"+61 4{random.randint(10,99)} {random.randint(100,999)} {random.randint(100,999)}",
            "businessPhones": [f"+61 3 {random.randint(1000,9999)} {random.randint(1000,9999)}"],
            "accountEnabled": True,
            "createdDateTime": f"{employee['startDate']}T09:00:00Z",
            "lastSignInDateTime": "2025-08-23T08:45:00Z",
            "assignedLicenses": ["Office 365 E3", "Teams", "OneDrive"],
            "memberOf": [f"{employee['department']}_Team", "All_Staff", "Melbourne_Office"],
            "lastUpdated": "2025-08-23T10:30:00Z",
            "dataSource": "entraAd-user"
        }
        
        with open(f"{data_dir}/entraAd-user/{ehs_id}.json", "w") as f:
            json.dump(entra_data, f, indent=2)
        
        # Google Cloud Identity User record
        gci_data = {
            "ehsId": ehs_id,
            "firstName": employee["firstName"],
            "lastName": employee["lastName"],
            "email": email,
            "upn": upn,
            "displayName": f"{employee['firstName']} {employee['lastName']}",
            "primaryEmail": email,
            "aliases": [f"{employee['firstName'][0].lower()}.{employee['lastName'].lower()}@{COMPANY_DOMAIN}"],
            "orgUnitPath": f"/{employee['department']}",
            "suspended": False,
            "archived": False,
            "lastLoginTime": "2025-08-23T08:45:00Z",
            "creationTime": f"{employee['startDate']}T09:00:00Z",
            "agreedToTerms": True,
            "isAdmin": employee["position"] in ["CEO", "COO", "CFO", "Operations Manager"],
            "isDelegatedAdmin": employee["position"] in ["Lead Developer", "Art Director", "HR Director"],
            "isMailboxSetup": True,
            "customSchemas": {
                "Employee_Info": {
                    "Employee_ID": ehs_id,
                    "Department": employee["department"],
                    "Manager": employee["manager"]
                }
            },
            "lastUpdated": "2025-08-23T10:30:00Z",
            "dataSource": "googleCloudIdentity-user"
        }
        
        with open(f"{data_dir}/googleCloudIdentity-user/{ehs_id}.json", "w") as f:
            json.dump(gci_data, f, indent=2)
        
        # Jira User Stats (only for employees with Jira access)
        if has_jira_access(employee["department"], employee["position"]):
            # Determine which projects they work on
            project_roles = []
            if employee["department"] == "Development":
                project_roles = [
                    {"projectKey": "MMORPG", "projectName": "Fantasy Realm Online", "roles": ["Developer"]},
                    {"projectKey": "HORROR", "projectName": "Midnight Terror", "roles": ["Developer"]},
                    {"projectKey": "CYBR", "projectName": "CyberRealm", "roles": ["Developer"]}
                ]
            elif employee["department"] == "Game Design":
                project_roles = [
                    {"projectKey": "MMORPG", "projectName": "Fantasy Realm Online", "roles": ["Designer"]},
                    {"projectKey": "HORROR", "projectName": "Midnight Terror", "roles": ["Designer"]}
                ]
            elif employee["department"] == "Art & Animation":
                project_roles = [
                    {"projectKey": "MMORPG", "projectName": "Fantasy Realm Online", "roles": ["Artist"]},
                    {"projectKey": "HORROR", "projectName": "Midnight Terror", "roles": ["Artist"]}
                ]
            elif employee["department"] == "QA":
                project_roles = [
                    {"projectKey": "MMORPG", "projectName": "Fantasy Realm Online", "roles": ["QA"]},
                    {"projectKey": "HORROR", "projectName": "Midnight Terror", "roles": ["QA"]},
                    {"projectKey": "YTCHAN", "projectName": "YouTube Channel", "roles": ["QA"]}
                ]
            elif employee["department"] == "YouTube Content":
                project_roles = [
                    {"projectKey": "YTCHAN", "projectName": "YouTube Channel", "roles": ["Content Creator"]},
                    {"projectKey": "STREAM", "projectName": "Live Streaming", "roles": ["Producer"]}
                ]
            
            jira_data = {
                "ehsId": ehs_id,
                "atlassianUserId": f"5b10ac8d82e05b22cc7d4e{i:02d}",
                "displayName": f"{employee['firstName']} {employee['lastName']}",
                "firstName": employee["firstName"],
                "lastName": employee["lastName"],
                "email": email,
                "accountType": "atlassian",
                "active": True,
                "projectRoles": project_roles,
                "jiraGroups": [
                    "jira-software-users",
                    f"{employee['department'].lower().replace(' & ', '-').replace(' ', '-')}-team"
                ],
                "workloadSummary": {
                    "assignedIssues": random.randint(5, 20),
                    "inProgressIssues": random.randint(1, 5),
                    "completedThisMonth": random.randint(3, 15),
                    "totalTimeLoggedThisMonth": f"{random.randint(20, 60)}h {random.randint(0, 59)}m",
                    "averageTimePerIssue": f"{random.randint(2, 8)}h {random.randint(0, 59)}m"
                },
                "recentActivity": {
                    "lastLogin": "2025-08-23T08:45:00Z",
                    "issuesCreatedLastMonth": random.randint(1, 8),
                    "issuesResolvedLastMonth": random.randint(2, 12),
                    "commentsLastMonth": random.randint(5, 30)
                },
                "lastUpdated": "2025-08-23T10:30:00Z",
                "dataSource": "jira-userStats"
            }
            
            with open(f"{data_dir}/jira-userStats/{ehs_id}.json", "w") as f:
                json.dump(jira_data, f, indent=2)
        
        # Confluence User Stats (for most employees)
        if has_confluence_access(employee["department"], employee["position"]):
            spaces = []
            if employee["department"] == "Development":
                spaces = [
                    {"spaceKey": "DEV", "spaceName": "Development", "role": "contributor", "pagesCreated": random.randint(3, 15), "pagesModified": random.randint(10, 40), "commentsAdded": random.randint(5, 25)},
                    {"spaceKey": "TECH", "spaceName": "Technical Documentation", "role": "contributor", "pagesCreated": random.randint(2, 8), "pagesModified": random.randint(5, 20), "commentsAdded": random.randint(2, 15)}
                ]
            elif employee["department"] == "Game Design":
                spaces = [
                    {"spaceKey": "DESIGN", "spaceName": "Game Design", "role": "contributor", "pagesCreated": random.randint(5, 20), "pagesModified": random.randint(15, 50), "commentsAdded": random.randint(8, 30)},
                    {"spaceKey": "DOCS", "spaceName": "Game Documentation", "role": "contributor", "pagesCreated": random.randint(3, 12), "pagesModified": random.randint(10, 35), "commentsAdded": random.randint(5, 20)}
                ]
            else:
                spaces = [
                    {"spaceKey": "COMPANY", "spaceName": "Company Wiki", "role": "contributor", "pagesCreated": random.randint(1, 5), "pagesModified": random.randint(3, 15), "commentsAdded": random.randint(2, 10)}
                ]
            
            confluence_data = {
                "ehsId": ehs_id,
                "atlassianUserId": f"5b10ac8d82e05b22cc7d4e{i:02d}",
                "displayName": f"{employee['firstName']} {employee['lastName']}",
                "firstName": employee["firstName"],
                "lastName": employee["lastName"],
                "email": email,
                "spacesActiveIn": spaces,
                "totalContributionSummary": {
                    "totalPagesCreated": sum(s["pagesCreated"] for s in spaces),
                    "totalPagesModified": sum(s["pagesModified"] for s in spaces),
                    "totalCommentsAdded": sum(s["commentsAdded"] for s in spaces),
                    "totalBlogPostsCreated": random.randint(0, 3),
                    "totalAttachmentsUploaded": random.randint(2, 15)
                },
                "top10SpacesActivity": spaces[:2],  # Top 2 for simplicity
                "recentActivity": {
                    "lastLogin": "2025-08-23T08:45:00Z",
                    "pagesCreatedLastMonth": random.randint(1, 5),
                    "pagesModifiedLastMonth": random.randint(3, 15),
                    "commentsLastMonth": random.randint(2, 12)
                },
                "lastUpdated": "2025-08-23T10:30:00Z",
                "dataSource": "confluence-userStats"
            }
            
            with open(f"{data_dir}/confluence-userStats/{ehs_id}.json", "w") as f:
                json.dump(confluence_data, f, indent=2)
        
        # Calendar Availability Summary (all employees)
        calendar_data = {
            "ehsId": ehs_id,
            "upn": upn,
            "firstName": employee["firstName"],
            "lastName": employee["lastName"],
            "displayName": f"{employee['firstName']} {employee['lastName']}",
            "workingHours": {
                "timezone": "Australia/Melbourne",
                "monday": {"start": "09:00", "end": "17:00"},
                "tuesday": {"start": "09:00", "end": "17:00"},
                "wednesday": {"start": "09:00", "end": "17:00"},
                "thursday": {"start": "09:00", "end": "17:00"},
                "friday": {"start": "09:00", "end": "17:00"},
                "saturday": None,
                "sunday": None
            },
            "availabilitySummary": {
                "currentStatus": random.choice(["Available", "Busy", "In a meeting", "Focus time"]),
                "nextMeeting": {
                    "title": random.choice(["Team Standup", "Sprint Planning", "Design Review", "1:1 Meeting"]),
                    "start": "2025-08-23T14:00:00Z",
                    "end": "2025-08-23T15:00:00Z"
                },
                "weeklyMeetingLoad": {
                    "totalMeetingHours": random.randint(8, 20),
                    "focusTimeHours": random.randint(15, 25),
                    "availableHours": random.randint(5, 15),
                    "meetingDensity": random.choice(["light", "moderate", "heavy"])
                }
            },
            "lastUpdated": "2025-08-23T10:30:00Z",
            "dataSource": "calendar-availabilitySummary"
        }
        
        with open(f"{data_dir}/calendar-availabilitySummary/{ehs_id}.json", "w") as f:
            json.dump(calendar_data, f, indent=2)
        
        # Teams User Activity Summary (all employees)
        teams_data = {
            "ehsId": ehs_id,
            "upn": upn,
            "firstName": employee["firstName"],
            "lastName": employee["lastName"],
            "displayName": f"{employee['firstName']} {employee['lastName']}",
            "userPrincipalName": upn,
            "activeTeamsGroups": [
                {
                    "teamId": f"19:{employee['department'].lower().replace(' ', '')}team@thread.v2",
                    "teamName": f"{employee['department']} Team",
                    "teamType": "private",
                    "membershipType": "member",
                    "role": "owner" if employee["position"] in ["CEO", "Lead Developer", "Art Director"] else "member",
                    "joinedDate": f"{employee['startDate']}T10:00:00Z",
                    "lastActivity": "2025-08-23T08:45:00Z",
                    "isArchived": False
                },
                {
                    "teamId": "19:allstaff@thread.v2",
                    "teamName": "All Staff",
                    "teamType": "public",
                    "membershipType": "member",
                    "role": "member",
                    "joinedDate": f"{employee['startDate']}T09:00:00Z",
                    "lastActivity": "2025-08-22T16:30:00Z",
                    "isArchived": False
                }
            ],
            "activitySummary": {
                "totalTeams": 2,
                "totalChannels": random.randint(4, 12),
                "messagesSentLastWeek": random.randint(15, 60),
                "reactionsLastWeek": random.randint(8, 35),
                "meetingsAttendedLastWeek": random.randint(3, 12),
                "callsInitiatedLastWeek": random.randint(0, 5),
                "filesSharedLastWeek": random.randint(1, 8),
                "lastActiveDate": "2025-08-23T08:45:00Z",
                "averageDailyActivity": random.choice(["low", "moderate", "high"])
            },
            "lastUpdated": "2025-08-23T10:30:00Z",
            "dataSource": "teams-userActivitySummary"
        }
        
        with open(f"{data_dir}/teams-userActivitySummary/{ehs_id}.json", "w") as f:
            json.dump(teams_data, f, indent=2)
        
        # Slack User Activity Summary (all employees)
        slack_data = {
            "ehsId": ehs_id,
            "upn": upn,
            "firstName": employee["firstName"],
            "lastName": employee["lastName"],
            "displayName": f"{employee['firstName']} {employee['lastName']}",
            "slackUserId": f"U{random.randint(1000000000, 9999999999)}",
            "slackUsername": f"{employee['firstName'].lower()}.{employee['lastName'].lower()}",
            "slackDisplayName": f"{employee['firstName']} {employee['lastName']}",
            "slackEmail": email,
            "activeSlackWorkspaces": [
                {
                    "workspaceId": "T1234567890",
                    "workspaceName": "Full Metal Productions",
                    "workspaceDomain": "fullmetalproductions.slack.com",
                    "membershipType": "regular",
                    "joinedDate": f"{employee['startDate']}T09:00:00Z",
                    "isActive": True,
                    "lastActivity": "2025-08-23T08:45:00Z"
                }
            ],
            "activeSlackChannels": [
                {
                    "channelId": f"C{random.randint(1000000000, 9999999999)}",
                    "channelName": f"{employee['department'].lower().replace(' ', '-').replace('&', 'and')}",
                    "channelType": "private",
                    "membershipType": "member",
                    "joinedDate": f"{employee['startDate']}T10:00:00Z",
                    "lastActivity": "2025-08-23T08:45:00Z",
                    "messagesSentLastWeek": random.randint(5, 25),
                    "reactionsLastWeek": random.randint(3, 18),
                    "isArchived": False
                },
                {
                    "channelId": "C2345678901",
                    "channelName": "general",
                    "channelType": "public",
                    "membershipType": "member",
                    "joinedDate": f"{employee['startDate']}T09:00:00Z",
                    "lastActivity": "2025-08-22T16:30:00Z",
                    "messagesSentLastWeek": random.randint(2, 12),
                    "reactionsLastWeek": random.randint(5, 20),
                    "isArchived": False
                }
            ],
            "activitySummary": {
                "totalChannels": random.randint(6, 15),
                "totalDirectMessages": random.randint(3, 12),
                "messagesSentLastWeek": random.randint(15, 50),
                "reactionsLastWeek": random.randint(12, 45),
                "filesSharedLastWeek": random.randint(1, 8),
                "threadsStartedLastWeek": random.randint(0, 4),
                "lastActiveDate": "2025-08-23T08:45:00Z",
                "averageDailyActivity": random.choice(["low", "moderate", "high"]),
                "onlineStatus": random.choice(["active", "away", "do_not_disturb"])
            },
            "lastUpdated": "2025-08-23T10:30:00Z",
            "dataSource": "slack-userActivitySummary"
        }
        
        with open(f"{data_dir}/slack-userActivitySummary/{ehs_id}.json", "w") as f:
            json.dump(slack_data, f, indent=2)

def generate_project_data():
    """Generate Jira project summary files."""
    data_dir = "c:/git/EH-HackAThon-WWIZ/data"
    
    for project_key, project_info in PROJECTS.items():
        if project_info["type"] in ["game", "minecraft_mod"]:
            # Determine team members based on project type
            team_members = []
            if project_info["status"] == "in_production":
                # Active projects have more team members
                for employee in EMPLOYEES:
                    if employee["department"] in ["Development", "Game Design", "Art & Animation", "QA"]:
                        team_members.append({
                            "ehsId": generate_ehs_id(EMPLOYEES.index(employee) + 1),
                            "displayName": f"{employee['firstName']} {employee['lastName']}",
                            "roles": ["Developer" if employee["department"] == "Development" else 
                                    "Designer" if employee["department"] == "Game Design" else
                                    "Artist" if employee["department"] == "Art & Animation" else "QA"]
                        })
            
            # Generate epic and ticket data
            epics = []
            if project_info["status"] == "in_production":
                epics = [
                    {
                        "epicKey": f"{project_key}-100",
                        "epicName": "Core Gameplay Systems",
                        "statusCounts": {
                            "To Do": random.randint(3, 8),
                            "In Progress": random.randint(2, 5),
                            "Code Review": random.randint(0, 3),
                            "Testing": random.randint(1, 4),
                            "Done": random.randint(5, 15)
                        }
                    },
                    {
                        "epicKey": f"{project_key}-200", 
                        "epicName": "Art & Animation",
                        "statusCounts": {
                            "To Do": random.randint(4, 10),
                            "In Progress": random.randint(1, 4),
                            "Review": random.randint(0, 2),
                            "Done": random.randint(8, 20)
                        }
                    },
                    {
                        "epicKey": f"{project_key}-300",
                        "epicName": "Audio & Music",
                        "statusCounts": {
                            "To Do": random.randint(2, 6),
                            "In Progress": random.randint(1, 3),
                            "Done": random.randint(3, 8)
                        }
                    }
                ]
            elif project_info["status"] == "released":
                epics = [
                    {
                        "epicKey": f"{project_key}-100",
                        "epicName": "Core Gameplay Systems",
                        "statusCounts": {
                            "Done": random.randint(15, 30)
                        }
                    },
                    {
                        "epicKey": f"{project_key}-200",
                        "epicName": "Post-Launch Support",
                        "statusCounts": {
                            "To Do": random.randint(1, 3),
                            "In Progress": random.randint(0, 2),
                            "Done": random.randint(5, 12)
                        }
                    }
                ]
            
            project_data = {
                "projectKey": project_key,
                "projectName": project_info["name"],
                "projectType": "software",
                "projectCategory": "Game Development" if project_info["type"] == "game" else "Minecraft Mods",
                "description": f"{project_info['name']} - {project_info['status'].replace('_', ' ').title()}",
                "lead": "Tim Firman" if project_key in ["MMORPG", "HORROR"] else "Jordan Martinez",
                "issueTypeScheme": "Game Development Issue Types",
                "workflowScheme": "Game Development Workflow",
                "ticketsByEpicAndStatus": epics,
                "usersAndRoles": team_members[:10],  # Limit to 10 for readability
                "projectStats": {
                    "totalIssues": sum(sum(epic["statusCounts"].values()) for epic in epics),
                    "openIssues": sum(sum(v for k, v in epic["statusCounts"].items() if k != "Done") for epic in epics),
                    "completedIssues": sum(epic["statusCounts"].get("Done", 0) for epic in epics),
                    "totalTimeSpent": f"{random.randint(200, 800)}h {random.randint(0, 59)}m",
                    "averageResolutionTime": f"{random.randint(1, 7)}.{random.randint(1, 9)} days"
                },
                "components": ["Gameplay", "UI", "Audio", "Graphics", "Networking"] if project_info["type"] == "game" else ["Core", "API", "Config"],
                "versions": [f"{i}.{j}.{k}" for i in range(1, 3) for j in range(0, 2) for k in range(0, 3)][:5],
                "lastUpdated": "2025-08-23T10:30:00Z",
                "dataSource": "jira-projectSummary"
            }
            
            with open(f"{data_dir}/jira-projectSummary/{project_key}.json", "w") as f:
                json.dump(project_data, f, indent=2)

def generate_confluence_spaces():
    """Generate Confluence space summary files."""
    data_dir = "c:/git/EH-HackAThon-WWIZ/data"
    
    spaces = {
        "DEV": {
            "spaceName": "Development Team",
            "description": "Technical documentation and development processes for Full Metal Productions",
            "type": "team"
        },
        "DESIGN": {
            "spaceName": "Game Design", 
            "description": "Game design documents, concepts, and design processes",
            "type": "team"
        },
        "ART": {
            "spaceName": "Art & Animation",
            "description": "Art style guides, asset libraries, and animation documentation", 
            "type": "team"
        },
        "COMPANY": {
            "spaceName": "Company Wiki",
            "description": "Company-wide policies, procedures, and general information",
            "type": "global"
        },
        "YOUTUBE": {
            "spaceName": "YouTube Content",
            "description": "Content planning, production guides, and YouTube channel documentation",
            "type": "team"
        }
    }
    
    for space_key, space_info in spaces.items():
        # Generate sample articles
        articles = []
        article_count = random.randint(15, 40)
        
        for i in range(article_count):
            author_employee = random.choice(EMPLOYEES)
            author_ehs_id = generate_ehs_id(EMPLOYEES.index(author_employee) + 1)
            
            articles.append({
                "pageId": f"{random.randint(10000, 99999)}",
                "title": f"Sample Article {i+1} for {space_info['spaceName']}",
                "type": "page",
                "summary": f"Documentation related to {space_info['spaceName'].lower()} processes and procedures.",
                "author": f"{author_employee['firstName']} {author_employee['lastName']}",
                "authorEhsId": author_ehs_id,
                "created": f"2024-{random.randint(1,12):02d}-{random.randint(1,28):02d}T{random.randint(9,17):02d}:{random.randint(0,59):02d}:00Z",
                "lastModified": f"2025-0{random.randint(1,8)}-{random.randint(1,23):02d}T{random.randint(9,17):02d}:{random.randint(0,59):02d}:00Z",
                "wordCount": random.randint(500, 3000),
                "viewCount": random.randint(20, 200),
                "labels": ["documentation", space_key.lower()]
            })
        
        # Generate contributors
        contributors = []
        for employee in EMPLOYEES[:random.randint(8, 15)]:
            ehs_id = generate_ehs_id(EMPLOYEES.index(employee) + 1)
            contributors.append({
                "ehsId": ehs_id,
                "displayName": f"{employee['firstName']} {employee['lastName']}",
                "role": "administrator" if employee["position"] in ["CEO", "Lead Developer", "Art Director"] else "contributor",
                "pagesCreated": random.randint(1, 8),
                "pagesModified": random.randint(5, 25),
                "lastActivity": f"2025-08-{random.randint(20,23):02d}T{random.randint(9,17):02d}:{random.randint(0,59):02d}:00Z"
            })
        
        space_data = {
            "spaceKey": space_key,
            "spaceName": space_info["spaceName"],
            "spaceType": space_info["type"],
            "description": space_info["description"],
            "homepageTitle": f"{space_info['spaceName']} Home",
            "articles": articles[:10],  # Limit to 10 for readability
            "contributors": contributors,
            "activitySummary": {
                "totalPages": len(articles),
                "totalBlogPosts": random.randint(3, 12),
                "totalComments": random.randint(50, 200),
                "totalAttachments": random.randint(25, 100),
                "averageViewsPerPage": sum(a["viewCount"] for a in articles) // len(articles),
                "mostViewedPage": max(articles, key=lambda x: x["viewCount"])["title"],
                "recentlyUpdatedPages": random.randint(5, 15),
                "activeContributors": len(contributors)
            },
            "lastUpdated": "2025-08-23T10:30:00Z",
            "dataSource": "confluence-spacesSummary"
        }
        
        with open(f"{data_dir}/confluence-spacesSummary/{space_key}.json", "w") as f:
            json.dump(space_data, f, indent=2)

if __name__ == "__main__":
    print("Generating test data for Full Metal Productions...")
    print(f"Creating data for {len(EMPLOYEES)} employees...")
    
    generate_employee_data()
    print("✅ Employee data generated")
    
    generate_project_data()
    print("✅ Project data generated")
    
    generate_confluence_spaces()
    print("✅ Confluence spaces generated")
    
    print("\n🎉 All test data generated successfully!")
    print(f"📁 Data location: c:/git/EH-HackAThon-WWIZ/data/")
    print(f"👥 Employees: {len(EMPLOYEES)}")
    print(f"🎮 Projects: {len([p for p in PROJECTS.values() if p['type'] in ['game', 'minecraft_mod']])}")
    print(f"📚 Confluence Spaces: 5")
