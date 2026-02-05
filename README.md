# Loyalty Services Builders Documentation

This folder contains documentation for building new features in the Loyalty Services ecosystem, particularly around the Journey Builder system.

## Guides

| Guide | Description |
|-------|-------------|
| [Journey Builder Guide](./JOURNEY_BUILDER_GUIDE.md) | Overview of journey builder system |
| [Journey Templates](./journey-templates/README.md) | How to add and configure journey templates |
| [Offer Builder](./offer-builder/README.md) | How to add and configure reward types and offer flows |
| [Workspace Setup](./setup/README.md) | MCP server configuration for new collaborators |

## Development (WIP)

| Feature | Description |
|---------|-------------|
| [Complimentary Rideshare](./development/complimentary-rideshare/README.md) | New reward type for rideshare credits |

## Cursor AI Context

The `.cursor/rules/` folder contains rules that are automatically loaded by Cursor:
- `journey-builder-system.mdc` - Journey builder context
- `offer-builder-system.mdc` - Offer builder context

### MCP Server Setup

This workspace uses MCP servers for Linear, Notion, Slack, and Figma integration. See [setup/MCP_SETUP.md](./setup/MCP_SETUP.md) for configuration instructions.

## Related Codebases

| Codebase | Path | Description |
|----------|------|-------------|
| `benefits-svc` | `/benefits-svc` | Backend service for journeys, offers, audiences, and campaigns |
| `bilt-merchant-mobile` | `/bilt-frontend-mobile/apps/bilt-merchant-mobile` | Merchant/Dining mobile app |
| `bilt-property-mobile` | `/bilt-frontend-mobile/apps/bilt-property-mobile` | Property/Rent mobile app |

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Journey Builder System                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐     ┌─────────────────┐                   │
│  │  benefits-svc   │     │ bilt-frontend-  │                   │
│  │    (Backend)    │◀───▶│     mobile      │                   │
│  │                 │     │   (Frontend)    │                   │
│  └────────┬────────┘     └─────────────────┘                   │
│           │                                                     │
│  ┌────────▼────────┐                                           │
│  │   PostgreSQL    │                                           │
│  │   (Spanner)     │                                           │
│  └─────────────────┘                                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```
