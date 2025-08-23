#!/usr/bin/env python3
"""
AnythingLLM Document Cleanup Script

This script helps you view and delete documents from AnythingLLM via API.
Run this on your EC2 instance to manage uploaded files.
"""

import requests
import json
import sys
import os
from typing import List, Dict

def loadEnv():
    """Load environment variables from .importFiles.env file."""
    env = {}
    envPath = os.path.join("data-handling", "dataImport", ".importFiles.env")
    print(f"current working folder: {os.getcwd()}")
    if not os.path.exists(envPath):
        print(f"Environment file not found: {envPath}")
        sys.exit(1)

    with open(envPath, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            
            if not line or line.startswith("#"):
                continue
            
            if "=" in line:
                key, value = line.split("=", 1)
                env[key.strip()] = value.strip().strip('\'"')
                
    return env

def getHeaders(apiKey):
    return {
        'Authorization': f'Bearer {apiKey}',
        'Content-Type': 'application/json'
    }

def listAllDocuments(serverUrl, apiKey):
    """List all documents in AnythingLLM"""
    endpoint = f"{serverUrl}/api/v1/documents"
    
    try:
        response = requests.get(endpoint, headers=getHeaders(apiKey))
        if response.status_code == 200:
            return response.json()
        else:
            print(f"Error fetching documents: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"Error: {str(e)}")
        return None

def extractFileList(documentsData):
    """Extract file names from the documents structure"""
    files = []
    
    def extractFilesRecursive(items, path=""):
        for item in items:
            currentPath = f"{path}/{item['name']}" if path else item['name']
            
            if item['type'] == 'file':
                files.append({
                    'name': item['name'],
                    'id': item['id'],
                    'path': currentPath,
                    'size': item.get('size', 'Unknown')
                })
            elif item['type'] == 'folder' and 'items' in item:
                extractFilesRecursive(item['items'], currentPath)
    
    if documentsData and 'localFiles' in documentsData:
        localFiles = documentsData['localFiles']
        if 'items' in localFiles:
            extractFilesRecursive(localFiles['items'])
    
    return files

def deleteDocument(serverUrl, apiKey, docName):
    """Delete a specific document"""
    endpoint = f"{serverUrl}/api/v1/document/{docName}"
    
    try:
        response = requests.delete(endpoint, headers=getHeaders(apiKey))
        if response.status_code == 200:
            print(f"Deleted: {docName}")
            return True
        else:
            print(f"Failed to delete {docName}: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print(f"Error deleting {docName}: {str(e)}")
        return False

def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python cleanup_documents.py list                    # List all documents")
        print("  python cleanup_documents.py delete <filename>       # Delete specific file")
        print("  python cleanup_documents.py delete-pattern <pattern> # Delete files matching pattern")
        print("  python cleanup_documents.py count                   # Count total files")
        return
    
    env = loadEnv()
    serverUrl = env.get("ANYTHINGLLM_URL")
    apiKey = env.get("ANYTHINGLLM_API_KEY")
    
    if not serverUrl or not apiKey:
        print(f"Error: Missing configuration in .importFiles.env")
        print(f"serverUrl: {serverUrl}")
        print(f"apiKey: {'Set' if apiKey else 'Missing'}")
        return
    
    command = sys.argv[1].lower()
    
    if command == "list":
        print("Fetching all documents...")
        docs = listAllDocuments(serverUrl, apiKey)
        if docs:
            files = extractFileList(docs)
            print(f"\nFound {len(files)} files:")
            for file in files:
                print(f"  {file['path']} (ID: {file['id']}) - Size: {file['size']}")
        
    elif command == "count":
        print("Counting documents...")
        docs = listAllDocuments(serverUrl, apiKey)
        if docs:
            files = extractFileList(docs)
            print(f"Total files: {len(files)}")
            
            # Count by folder
            folders = {}
            for file in files:
                folder = "/".join(file['path'].split('/')[:-1]) or "root"
                folders[folder] = folders.get(folder, 0) + 1
            
            print("\nFiles by folder:")
            for folder, count in sorted(folders.items()):
                print(f"  {folder}: {count} files")
    
    elif command == "delete" and len(sys.argv) == 3:
        filename = sys.argv[2]
        print(f"Deleting: {filename}")
        deleteDocument(serverUrl, apiKey, filename)
    
    elif command == "delete-pattern":
        pattern = sys.argv[2] if len(sys.argv) > 2 else ""
        print(f"Deleting files matching pattern: '{pattern}'")
        print(f"Pattern length: {len(pattern)}")
        print(f"sys.argv: {sys.argv}")
        
        docs = listAllDocuments(serverUrl, apiKey)
        if docs:
            files = extractFileList(docs)
            # For empty pattern, match all files
            if pattern == "":
                matchingFiles = files
            else:
                matchingFiles = [f for f in files if pattern in f['name']]
            
            if not matchingFiles:
                print(f"No files found matching pattern: '{pattern}'")
                return
            
            print(f"Found {len(matchingFiles)} files matching pattern:")
            for file in matchingFiles:
                print(f"  {file['name']}")
            
            confirm = input(f"\nDelete {len(matchingFiles)} files? (y/N): ")
            if confirm.lower() == 'y':
                deleted = 0
                for file in matchingFiles:
                    if deleteDocument(serverUrl, apiKey, file['name']):
                        deleted += 1
                print(f"\nDeleted {deleted} out of {len(matchingFiles)} files")
            else:
                print("Cancelled")
    
    else:
        print("Invalid command. Use 'list', 'count', 'delete <filename>', or 'delete-pattern <pattern>'")

if __name__ == "__main__":
    main()
