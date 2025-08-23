"""
AnythingLLM File Import Script for WWIZ Knowledge Base

This script uploads files from a local directory structure to AnythingLLM,
preserving the folder hierarchy and embedding files in specified workspaces.

Features:
- Creates folder structure in AnythingLLM matching local directory
- Uploads JSON, TXT, XML, and CSV files
- Avoids duplicate uploads by checking existing files
- Embeds uploaded files in specified workspaces
- Supports dry-run mode for testing

Author: Tim Firman
Company: Full Metal Productions
Project: WWIZ (Who's Who in the Zoo)
"""

import requests
import os
import sys
from typing import Dict, List, Tuple

# Global configuration variables
serverUrl: str
apiKey: str
filePath: str
recursive: bool = True
workspaces: str
includedFileTypes: List[str] = []

# Testing vars ;)
dryRun: bool = False
testing: bool = False
smallBatchRun : bool = False
smallBatchSize : int = 0


def main() -> None:
    """
    Main entry point for the import script.
    
    Loads environment variables, builds file lists, creates folders,
    uploads files, and embeds them in workspaces.
    """
    env: Dict = loadEnv()
    
    serverURL = env.get("ANYTHINGLLM_URL")
    workSpaceSlug = env.get("WORKSPACE_SLUG") or env.get("AGENT_NAME")
    apiKey = env.get("ANYTHINGLLM_API_KEY")
    filePath = env.get("FILE_PATH")
    recursive = env.get("RECURSIVE")
    dryRun = env.get("DRY_RUN")
    workspaces = env.get("WORKSPACES")
    includedFileTypes = env.get("INCLUDED_FILE_TYPES", "txt,json,xml,csv").split(",")
    
    dryRun = dryRun.lower() == 'true' if isinstance(dryRun, str) else dryRun
    smallBatchRun = env.get("SMALL_BATCH", "false").lower() == 'true'
    smallBatchSize = int(env.get("SMALL_BATCH_LIMIT", 0))

    if not serverURL or not filePath:
        print(f"Error, variables missing. Check your .env\nserverURL: {serverURL}\nfilePath: {filePath}")
        if not apiKey:
            print("API_KEY missing - this is expected for testing")
        return
    else: 
        print("Variables Set")
        
    # Build list of files to upload with their target folders
    filesToUpload: Dict[str, Tuple[bytes, str]] = buildFileListWithFolders(filePath, recursive, smallBatchRun, smallBatchSize, includedFileTypes)
    
    # Get existing files to avoid duplicates
    existingFiles: List[str] = buildExistingFileList(serverURL, apiKey)
    filesToUpload = removeDuplicates(filesToUpload, existingFiles)
    
    if dryRun:
        print(f"Dry run enabled. Files to upload: {len(filesToUpload)}")
        for filePath, (content, targetFolder) in filesToUpload.items():
            print(f"File: {os.path.basename(filePath)} -> Folder: {targetFolder} - Size: {len(content)} bytes")
        return
    
    # Create folder structure in AnythingLLM
    folderStructure: List[str] = extractFolderStructure(filesToUpload)
    createFolderStructure(folderStructure, serverURL, apiKey)
    
    # Upload files to their respective folders
    uploadResults = uploadFilesToFolders(filesToUpload, serverURL, apiKey, workspaces)

    # Embed files in workspaces
    #  embedFilesInAgents(uploadResults, workspaces, serverURL, apiKey)

    print("All files processed and embedded in agent.")


def buildFileListWithFolders(filePath: str, recursive: bool, smallBatchRun: bool, smallBatchSize: int, includedFileTypes: List[str]) -> Dict[str, Tuple[bytes, str]]:
    """
    Build a dictionary of files to upload with their target folder paths.
    
    Args:
        filePath: Root directory to scan for files
        recursive: Whether to scan subdirectories recursively
        smallBatchRun: Whether to limit the number of files processed
        smallBatchSize: Maximum number of files to process when smallBatchRun is True
        includedFileTypes: List of file extensions to include (e.g., ['txt', 'json', 'xml', 'csv'])
        
    Returns:
        Dictionary mapping file paths to (file_content, target_folder) tuples
    """
    print(f"Building file list from: {filePath} (recursive={recursive})")
    if smallBatchRun:
        print(f"Small batch mode enabled: limiting to {smallBatchSize} files")
    
    filesDict: Dict[str, Tuple[bytes, str]] = {}
    
    if not os.path.exists(filePath) or not os.path.isdir(filePath):
        print(f"Error: {filePath} does not exist or is not a directory")
        sys.exit(1)
        
    # Check if the directory is empty
    if not any(os.scandir(filePath)):
        print(f"Error: Directory {filePath} is empty")
        sys.exit(1)
    
    if recursive:
        for root, dirs, files in os.walk(filePath):
            for file in files:
                # Check if we've reached the batch limit
                if smallBatchRun and len(filesDict) >= smallBatchSize:
                    print(f"Reached small batch limit of {smallBatchSize} files")
                    return filesDict
                    
                ext = file.split('.')[-1].lower()
                if ext in includedFileTypes:
                    fullPath = os.path.join(root, file)
                    # Calculate relative folder path for AnythingLLM
                    relativePath = os.path.relpath(root, filePath)
                    targetFolder = relativePath if relativePath != "." else ""
                    
                    with open(fullPath, "rb") as f:
                        filesDict[fullPath] = (f.read(), targetFolder)
    else:
        if os.path.isdir(filePath):
            for file in os.listdir(filePath):
                # Check if we've reached the batch limit
                if smallBatchRun and len(filesDict) >= smallBatchSize:
                    print(f"Reached small batch limit of {smallBatchSize} files")
                    return filesDict
                    
                ext = file.split('.')[-1].lower()
                if ext in includedFileTypes:
                    fullPath = os.path.join(filePath, file)
                    if os.path.isfile(fullPath):
                        with open(fullPath, "rb") as f:
                            filesDict[fullPath] = (f.read(), "")
        elif os.path.isfile(filePath):
            ext = filePath.split('.')[-1].lower()
            if ext in includedFileTypes:
                with open(filePath, "rb") as f:
                    filesDict[filePath] = (f.read(), "")
    
    return filesDict


def extractFolderStructure(filesToUpload: Dict[str, Tuple[bytes, str]]) -> List[str]:
    """
    Extract unique folder paths from the files to upload.
    
    Args:
        filesToUpload: Dictionary of files with their target folders
        
    Returns:
        List of unique folder paths to create
    """
    folders = set()
    for filePath, (content, targetFolder) in filesToUpload.items():
        if targetFolder:
            # Build hierarchical folder structure
            parts = targetFolder.split(os.sep)
            for i in range(1, len(parts) + 1):
                folders.add(os.sep.join(parts[:i]))
    
    return sorted(list(folders))


def createFolderStructure(folderStructure: List[str], serverUrl: str, apiKey: str) -> None:
    """
    Create folder structure in AnythingLLM.
    
    Args:
        folderStructure: List of folder paths to create
        serverUrl: AnythingLLM server URL
        apiKey: API key for authentication
    """
    if not folderStructure:
        print("No folders to create")
        return
        
    print(f"Creating {len(folderStructure)} folders in AnythingLLM...")
    
    endpoint = f"{serverUrl}/api/v1/document/create-folder"
    auth = f"Bearer {apiKey}"
    headers = {'Authorization': auth, 'Content-Type': 'application/json'}
    
    for folder in folderStructure:
        payload = {"name": folder}
        
        try:
            response = requests.post(endpoint, headers=headers, json=payload)
            
            if response.status_code == 200:
                print(f"Created folder: {folder}")
            elif response.status_code == 409:
                print(f"Folder already exists: {folder}")
            else:
                print(f"Failed to create folder {folder}: {response.status_code} - {response.text}")
                
        except Exception as e:
            print(f"Error creating folder {folder}: {str(e)}")


def buildExistingFileList(serverUrl: str, apiKey: str) -> List[str]:
    """
    Build a list of existing files on the AnythingLLM server.
    
    Args:
        serverUrl: AnythingLLM server URL
        apiKey: API key for authentication
        
    Returns:
        List of existing file names
    """
    endpoint = f"{serverUrl}/api/v1/documents"
    auth = f"Bearer {apiKey}"
    headers = {'Authorization': auth} 
    payload = {}
    
    try:
        response = requests.get(endpoint, headers=headers, data=payload)
        
        if response.status_code != 200:
            print(f"Error fetching existing files: {response.text}")
            return []
        
        data = response.json()
        localFiles = data.get("localFiles", {})
        returnDocumentNames = []
        
        if localFiles.get("name") == "documents" and "items" in localFiles:
            documents = localFiles["items"]
            returnDocumentNames = extractFileNamesRecursively(documents)
        
        return returnDocumentNames
        
    except Exception as e:
        print(f"Error fetching existing files: {str(e)}")
        return []


def extractFileNamesRecursively(items: List[Dict]) -> List[str]:
    """
    Recursively extract file names from AnythingLLM document structure.
    
    Args:
        items: List of document items from API response
        
    Returns:
        List of cleaned file names
    """
    fileNames = []
    
    for item in items:
        if item["type"] == "file" and item.get("name"):
            cleanedName = cleanAPIFileNames(item)
            fileNames.append(cleanedName)
        elif item["type"] == "folder" and "items" in item:
            fileNames.extend(extractFileNamesRecursively(item["items"]))
    
    return fileNames
    

def cleanAPIFileNames(fileDict: Dict) -> str:
    """
    Remove UUID suffix from filename returned by the API.
    
    File names from API include a UUID suffix that needs to be removed.
    
    Args:
        fileDict: Dictionary containing file information from API
        
    Returns:
        Cleaned filename without UUID suffix
    """
    filename = fileDict["name"]
    uuid = fileDict["id"]
    toRemove = f"-{uuid}.json"
    newFilename = filename.replace(toRemove, "")
    return newFilename    
    

def removeDuplicates(filesToUpload: Dict[str, Tuple[bytes, str]], existingFiles: List[str]) -> Dict[str, Tuple[bytes, str]]:
    """
    Remove files that already exist on the server from the upload list.
    
    Args:
        filesToUpload: Dictionary of files to upload
        existingFiles: List of existing file names on server
        
    Returns:
        Filtered dictionary with duplicates removed
    """
    cleanedFilesToUpload = {}
    skippedCount = 0
    
    for filePath, (content, targetFolder) in filesToUpload.items():
        filename = os.path.basename(filePath)
        if filename not in existingFiles:
            cleanedFilesToUpload[filePath] = (content, targetFolder)
        else:
            skippedCount += 1
            
        # Testing limit
        if testing and len(cleanedFilesToUpload) >= 10:
            break
    
    if skippedCount > 0:
        print(f"Skipped {skippedCount} duplicate files")
            
    return cleanedFilesToUpload


def uploadFilesToFolders(filesToUpload: Dict[str, Tuple[bytes, str]], serverUrl: str, apiKey: str, workspaces: str) -> List[str]:
    """
    Upload files to AnythingLLM server, organizing them into folders.
    
    Args:
        filesToUpload: Dictionary of files with content and target folders
        serverUrl: AnythingLLM server URL
        apiKey: API key for authentication
        workspaces: Comma-separated list of workspaces to add files to
        
    Returns:
        List of document locations for embedding
    """
    endpoint = f"{serverUrl}/api/v1/document/upload"
    auth = f"Bearer {apiKey}"
    headers = {'Authorization': auth}
    
    result = []
    contentTypeMap = {
        'txt': 'text/plain',
        'json': 'application/json',
        'xml': 'application/xml',
        'csv': 'text/csv'
    }
    
    uploadCount = 0
    totalFiles = len(filesToUpload)
    
    for filePath, (fileContent, targetFolder) in filesToUpload.items():
        filename = os.path.basename(filePath)
        
        # Determine content type based on file extension
        ext = filename.split('.')[-1].lower()
        contentType = contentTypeMap.get(ext, 'text/plain')
        
        # Prepare multipart form data
        files = {
            'file': (filename, fileContent, contentType)
        }
        
        data = {}
        if workspaces:
            data['addToWorkspaces'] = workspaces
        if targetFolder:
            targetEndpoint = f'{endpoint}/{targetFolder}'
        else:
            targetEndpoint = endpoint
        
        try:
            response = requests.post(targetEndpoint, headers=headers, files=files, data=data)

            if response.status_code == 200:
                uploadCount += 1
                
                jsonResponse = response.json()
                for document in jsonResponse.get('documents', []):
                    result.append(document['location'])
                    
                print(f"Uploaded: {filename} ({uploadCount}/{totalFiles})")
            else:
                print(f"Failed to upload {filename}: {response.status_code} - {response.text}")

        except Exception as e:
            print(f"Error uploading {filename}: {str(e)}")
            
        if uploadCount % 25 == 0 and uploadCount > 0:
            print(f"Progress: {uploadCount}/{totalFiles} files uploaded...")
    
    print(f"Upload complete. Successfully uploaded {uploadCount} out of {totalFiles} files.")
    return result


def embedFilesInAgents(uploadResults: List[str], workspaces: str, serverUrl: str, apiKey: str) -> None:
    """
    Embed uploaded files in specified workspaces.
    
    Args:
        uploadResults: List of document locations to embed
        workspaces: Comma-separated list of workspace names
        serverUrl: AnythingLLM server URL
        apiKey: API key for authentication
    """
    if not uploadResults:
        print("No files to embed.")
        return
    
    workspacesList = [ws.strip() for ws in workspaces.split(",") if ws.strip()]

    if not workspacesList:
        print("No workspaces specified.")
        return
    
    for workspace in workspacesList:
        embedFilesInAgent(uploadResults, workspace, serverUrl, apiKey)


def embedFilesInAgent(uploadResults: List[str], workspace: str, serverUrl: str, apiKey: str) -> None:
    """
    Embed files in a specific workspace.
    
    Args:
        uploadResults: List of document locations to embed
        workspace: Workspace name
        serverUrl: AnythingLLM server URL
        apiKey: API key for authentication
    """
    endpoint = f"{serverUrl}/api/v1/workspace/{workspace}/update-embeddings"
    auth = f"Bearer {apiKey}"
    headers = {'Authorization': auth, 'Content-Type': 'application/json'}
    
    payload = {
        "adds": uploadResults
    }

    try:
        response = requests.post(endpoint, headers=headers, json=payload)

        if response.status_code == 200:
            print(f"Successfully embedded {len(uploadResults)} files in workspace '{workspace}'")
        else:
            print(f"Failed to embed files in workspace '{workspace}': {response.status_code} - {response.text}")

    except Exception as e:
        print(f"Error embedding files in workspace '{workspace}': {str(e)}")


def loadEnv() -> Dict[str, str]:
    """
    Load environment variables from .env file.
    
    Returns:
        Dictionary of environment variables
    """
    env = {}
    envPath = os.path.join("data-handling", "dataImport", ".importFiles.env")

    if not os.path.exists(envPath):
        print(f"Environment file not found: {envPath}")
        exit(1)

    with open(envPath, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            
            if not line or line.startswith("#"):
                continue
            
            if "=" in line:
                key, value = line.split("=", 1)
                env[key.strip()] = value.strip().strip('\'"')
                
    return env


if __name__ == "__main__":
    main()
    