# Security policy

## Reporting a vulnerability

Please do not open a public issue for a vulnerability that could expose credentials or execute untrusted code. Contact the maintainer through the private security-reporting option on GitHub when available.

Include the affected file, reproduction steps, impact, and a suggested mitigation. Never include real tokens, passwords, cookies, or private user data.

## Trust boundaries

Codex Skills Hub is a catalog and installer. A listed skill may contain instructions or scripts maintained elsewhere. Before using a skill:

- inspect its upstream repository and license;
- read `SKILL.md` and referenced scripts;
- review requested MCP servers, plugins, and permissions;
- authenticate services individually;
- keep secrets outside repositories and chat transcripts.

The catalog's presence is not a security endorsement of every upstream integration.

