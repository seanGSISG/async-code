# Async Code Agent

Use Claude Code / CodeX CLI to perform multiple tasks in parallel with a Codex-style UI.

A code agent task management system that provides parallel execution of AI-powered coding tasks. Users can run multiple Claude Code agents simultaneously through a Codex-style web interface, with support for different agents for comparison and evaluation.

![async-code-ui](https://github.com/user-attachments/assets/e490c605-681a-4abb-a440-323e15f1a90d)


![async-code-review](https://github.com/user-attachments/assets/bbf71c82-636c-487b-bb51-6ad0b393c2ef)


## Key Features

- 🤖 **Multi-Agent Support**: Run Claude Code and other AI agents in parallel
- 🔄 **Parallel Task Management**: Execute multiple coding tasks simultaneously
- 🌐 **Codex-Style Web UI**: Clean interface for managing agent tasks
- 🔍 **Agent Comparison**: Compare outputs from different AI models
- 🐳 **Containerized Execution**: Secure sandboxed environment for each task
- 🔗 **Git Integration**: Automatic repository cloning, commits, and PR creation
- 🔓 **Optional Authentication**: Skip auth setup for local development
- **Selfhost**: Deploy your own parallel code agent platform.

## Architecture

- **Frontend**: Next.js with TypeScript and TailwindCSS
- **Backend**: Python Flask API with Docker orchestration
- **Agents**: Claude Code (Anthropic) with extensible support for other models
- **Task Management**: Parallel execution system based on container

## Prerequisites

- Docker and Docker Compose installed
- (Optional) Supabase account for persistent data storage

## Quick Start

1. **Clone the repository**
   ```bash
   git clone <this-repo>
   cd async-code
   ```

2. **Create the environment file**
   ```bash
   cp server/.env.example server/.env
   ```

   **Authentication Options:**

   You can use either an API key OR your Anthropic subscription:

   - **Option A: API Key** - Set `ANTHROPIC_API_KEY` in `server/.env`
   - **Option B: Claude Code Subscription** ([#15](https://github.com/ObservedObserver/async-code/pull/15)) - Leave API key blank and configure via web UI:
     1. Log in to Claude Code on your laptop: `claude auth login`
     2. Copy contents of `~/.claude/.credentials.json`
     3. Paste into Settings > User Credentials in the web interface

     ![Claude Code Credentials](https://github.com/user-attachments/assets/5fe87d4b-2acb-4095-a373-f3ed9f423081)

   **For local development without authentication:**
   - Add `NEXT_PUBLIC_DISABLE_AUTH=true` to skip Supabase auth setup
   - Run `db/init_supabase-local.sql` in Supabase SQL Editor for a mock user

   **For production:** Set `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` and configure auth providers (see [Supabase Setup](#supabase-setup)).

3. **Build and start the stack**
   ```bash
   docker-compose up --build -d
   ```

   - Frontend: http://localhost:3000
   - Backend API: http://localhost:5000

## Supabase Setup

**Option A: Local Development (No Auth)**
1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Run `db/init_supabase-local.sql` in SQL Editor (creates mock user)
3. Add credentials to `server/.env` and set `NEXT_PUBLIC_DISABLE_AUTH=true`

**Option B: Production (With Auth)**
1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Run `db/init_supabase.sql` in SQL Editor
3. Configure auth providers: **Authentication → Providers** (Email/GitHub/Google)
4. Add credentials to `server/.env`

See `db/README.md` for detailed authentication setup instructions.

## Usage

1. **Setup GitHub Token**: Enter your GitHub token in the web interface
2. **Configure Repository**: Specify target repository and branch
3. **Select Agent**: Choose your preferred AI agent (Claude Code, etc.)
4. **Submit Tasks**: Start multiple coding tasks in parallel
5. **Compare Results**: Review and compare outputs from different agents
6. **Create PRs**: Generate pull requests from successful tasks

## Environment Variables

```bash
# server/.env

# Anthropic API (optional if using Claude Code credentials via web UI)
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Supabase (required)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Optional: Disable authentication for local development
NEXT_PUBLIC_DISABLE_AUTH=true  # Set to false or omit for production

# Flask configuration
FLASK_ENV=production
FLASK_DEBUG=False
```

**Note:** If `ANTHROPIC_API_KEY` is not set, the system will use Claude Code credentials configured in the web UI (Settings > User Credentials).


## Development

```bash
# Run all services
docker-compose up

# Development mode
cd async-code-web && npm run dev  # Frontend
cd server && python main.py      # Backend
```

## Production Deployment

1. Set `FLASK_ENV=production` in `server/.env` and export `NODE_ENV=production` before running the stack.
2. Build and start the containers:
   ```bash
   NODE_ENV=production docker-compose up --build -d
   ```
3. Monitor the logs with:
   ```bash
   docker-compose logs -f
   ```


## License

See LICENSE file for details.

