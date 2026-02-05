# MCP Server Setup for Cursor

This workspace uses several MCP (Model Context Protocol) servers to enhance AI capabilities. MCP settings are stored at the **user level** (`~/.cursor/mcp.json`), not in the workspace, so each collaborator needs to configure them individually.

## Required MCP Servers

### 1. Linear (Issue Tracking)

**Purpose**: Access Linear issues, projects, and documentation directly from Cursor.

```json
"linear": {
  "url": "https://mcp.linear.app/sse"
}
```

**Setup**: No additional configuration needed - authenticates via browser when first used.

### 2. Notion (Documentation)

**Purpose**: Search and access Notion workspace for PRDs, specs, and documentation.

```json
"Notion": {
  "url": "https://mcp.notion.com/mcp",
  "headers": {}
}
```

**Setup**: Authenticates via browser when first used.

### 3. Slack (Team Communication)

**Purpose**: Search channels, read messages, and post updates.

```json
"slack": {
  "command": "/opt/homebrew/bin/npx",
  "args": ["-y", "@modelcontextprotocol/server-slack"],
  "env": {
    "SLACK_BOT_TOKEN": "<your-bot-token>",
    "SLACK_USER_TOKEN": "<your-user-token>",
    "SLACK_TEAM_ID": "<your-team-id>",
    "NPM_CONFIG_UPDATE_NOTIFIER": "false",
    "PATH": "/opt/homebrew/bin:/usr/bin:/bin"
  }
}
```

**Setup**: 
1. Create a Slack app at https://api.slack.com/apps
2. Add required OAuth scopes for bot and user tokens
3. Install to your workspace and copy the tokens

### 4. Figma Desktop (Design)

**Purpose**: Access Figma designs and generate code from design files.

```json
"Figma Desktop": {
  "url": "http://127.0.0.1:3845/mcp",
  "headers": {}
}
```

**Setup**: Requires Figma Desktop app with MCP plugin enabled.

## Optional MCP Servers

### Devin (AI Agent)

**Purpose**: Delegate complex tasks to Devin AI agent.

```json
"devin": {
  "url": "https://mcp.devin.ai/sse",
  "headers": {
    "Authorization": "Bearer <your-devin-api-key>"
  }
}
```

**Setup**: Requires Devin account and API key.

## Installation

1. Copy `mcp.json.example` from this folder to `~/.cursor/mcp.json`
2. Fill in your credentials for each service
3. Restart Cursor

```bash
cp setup/mcp.json.example ~/.cursor/mcp.json
# Edit ~/.cursor/mcp.json with your credentials
```

## Troubleshooting

- **MCP server not connecting**: Check that the service is running and accessible
- **Authentication errors**: Verify your tokens/API keys are correct
- **Slack not working**: Ensure npx is available at the configured path (check with `which npx`)
