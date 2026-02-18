-- ═══════════════════════════════════════════════════
--       AutoPilot-Hub - Database Initialization
-- ═══════════════════════════════════════════════════

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ── Schema: Core ──
CREATE SCHEMA IF NOT EXISTS core;

-- Tasks table
CREATE TABLE IF NOT EXISTS core.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_type VARCHAR(50) NOT NULL,
    source_service VARCHAR(50) NOT NULL,
    target_service VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    priority INTEGER DEFAULT 5,
    payload JSONB,
    result JSONB,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Service registry
CREATE TABLE IF NOT EXISTS core.services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'unknown',
    endpoint VARCHAR(255),
    last_heartbeat TIMESTAMP WITH TIME ZONE,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Configuration
CREATE TABLE IF NOT EXISTS core.config (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Audit log
CREATE TABLE IF NOT EXISTS core.audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    action VARCHAR(100) NOT NULL,
    service VARCHAR(50),
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ── Schema: Freelancer ──
CREATE SCHEMA IF NOT EXISTS freelancer;

-- Platforms
CREATE TABLE IF NOT EXISTS freelancer.platforms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) UNIQUE NOT NULL,
    url VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    last_check TIMESTAMP WITH TIME ZONE,
    metadata JSONB
);

-- Messages
CREATE TABLE IF NOT EXISTS freelancer.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    platform_id UUID REFERENCES freelancer.platforms(id),
    external_id VARCHAR(255),
    sender_name VARCHAR(255),
    content TEXT,
    direction VARCHAR(10) DEFAULT 'incoming',
    is_read BOOLEAN DEFAULT false,
    is_replied BOOLEAN DEFAULT false,
    reply_content TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    replied_at TIMESTAMP WITH TIME ZONE
);

-- Projects discovered
CREATE TABLE IF NOT EXISTS freelancer.projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    platform_id UUID REFERENCES freelancer.platforms(id),
    external_id VARCHAR(255),
    title VARCHAR(500),
    description TEXT,
    budget VARCHAR(100),
    skills JSONB,
    url VARCHAR(500),
    match_score FLOAT,
    status VARCHAR(20) DEFAULT 'discovered',
    proposal_id UUID,
    discovered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Proposals
CREATE TABLE IF NOT EXISTS freelancer.proposals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID REFERENCES freelancer.projects(id),
    content TEXT,
    price VARCHAR(50),
    delivery_time VARCHAR(50),
    status VARCHAR(20) DEFAULT 'draft',
    submitted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ── Schema: Email ──
CREATE SCHEMA IF NOT EXISTS email;

-- Emails
CREATE TABLE IF NOT EXISTS email.emails (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gmail_id VARCHAR(255) UNIQUE,
    thread_id VARCHAR(255),
    from_address VARCHAR(255),
    from_name VARCHAR(255),
    to_address VARCHAR(255),
    subject VARCHAR(1000),
    body TEXT,
    summary TEXT,
    classification VARCHAR(50),
    priority INTEGER DEFAULT 5,
    is_read BOOLEAN DEFAULT false,
    needs_reply BOOLEAN DEFAULT false,
    is_replied BOOLEAN DEFAULT false,
    labels JSONB,
    attachments JSONB,
    received_at TIMESTAMP WITH TIME ZONE,
    processed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Email drafts
CREATE TABLE IF NOT EXISTS email.drafts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email_id UUID REFERENCES email.emails(id),
    to_address VARCHAR(255),
    subject VARCHAR(1000),
    body TEXT,
    status VARCHAR(20) DEFAULT 'draft',
    approved_at TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Auto-response rules
CREATE TABLE IF NOT EXISTS email.rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100),
    condition_type VARCHAR(50),
    condition_value TEXT,
    action_type VARCHAR(50),
    action_value TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ── Schema: BugHunter ──
CREATE SCHEMA IF NOT EXISTS bughunter;

-- Targets
CREATE TABLE IF NOT EXISTS bughunter.targets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    domain VARCHAR(255) NOT NULL,
    platform VARCHAR(50),
    scope JSONB,
    is_active BOOLEAN DEFAULT true,
    last_scan TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Subdomains
CREATE TABLE IF NOT EXISTS bughunter.subdomains (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    target_id UUID REFERENCES bughunter.targets(id),
    subdomain VARCHAR(500) NOT NULL,
    ip_address VARCHAR(50),
    status_code INTEGER,
    technology JSONB,
    is_alive BOOLEAN DEFAULT false,
    first_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Findings
CREATE TABLE IF NOT EXISTS bughunter.findings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    target_id UUID REFERENCES bughunter.targets(id),
    subdomain_id UUID REFERENCES bughunter.subdomains(id),
    vulnerability_type VARCHAR(100),
    severity VARCHAR(20),
    title VARCHAR(500),
    description TEXT,
    url VARCHAR(1000),
    evidence TEXT,
    poc TEXT,
    tool VARCHAR(50),
    is_false_positive BOOLEAN DEFAULT false,
    is_reported BOOLEAN DEFAULT false,
    report_url VARCHAR(500),
    found_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Scans
CREATE TABLE IF NOT EXISTS bughunter.scans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    target_id UUID REFERENCES bughunter.targets(id),
    scan_type VARCHAR(50),
    status VARCHAR(20) DEFAULT 'pending',
    config JSONB,
    results_summary JSONB,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ── Schema: DevEnv ──
CREATE SCHEMA IF NOT EXISTS devenv;

-- Environments
CREATE TABLE IF NOT EXISTS devenv.environments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    template VARCHAR(100),
    path VARCHAR(500),
    config JSONB,
    status VARCHAR(20) DEFAULT 'created',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ── Schema: Reports ──
CREATE SCHEMA IF NOT EXISTS reports;

-- Daily reports
CREATE TABLE IF NOT EXISTS reports.daily_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_date DATE UNIQUE NOT NULL,
    content JSONB,
    summary TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ── Indexes ──
CREATE INDEX IF NOT EXISTS idx_tasks_status ON core.tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_created ON core.tasks(created_at);
CREATE INDEX IF NOT EXISTS idx_emails_classification ON email.emails(classification);
CREATE INDEX IF NOT EXISTS idx_emails_received ON email.emails(received_at);
CREATE INDEX IF NOT EXISTS idx_projects_status ON freelancer.projects(status);
CREATE INDEX IF NOT EXISTS idx_findings_severity ON bughunter.findings(severity);
CREATE INDEX IF NOT EXISTS idx_subdomains_target ON bughunter.subdomains(target_id);

-- ── Insert Default Data ──
INSERT INTO freelancer.platforms (name, url) VALUES
    ('khamsat', 'https://khamsat.com'),
    ('mostaql', 'https://mostaql.com')
ON CONFLICT (name) DO NOTHING;

INSERT INTO core.services (name, endpoint) VALUES
    ('main-agent', 'http://main-agent:8000'),
    ('freelancer-service', 'http://freelancer-service:8001'),
    ('email-service', 'http://email-service:8002'),
    ('devenv-service', 'http://devenv-service:8003'),
    ('bughunter-service', 'http://bughunter-service:8004'),
    ('telegram-bot', NULL),
    ('dashboard', 'http://dashboard:8080')
ON CONFLICT (name) DO NOTHING;

-- Done
SELECT 'AutoPilot-Hub database initialized successfully!' AS message;
