import { NextRequest } from 'next/server';
import { ApiResponse, RepoData, PR, LogEntry, PRMetrics } from '@/app/types';

// Mock data generator functions
function generateMockLogs(prNumber: number): LogEntry[] {
  const levels: ('info' | 'warn' | 'error' | 'debug')[] = ['info', 'warn', 'error', 'debug'];
  const sources = ['build', 'test', 'deploy', 'lint'];
  const logs: LogEntry[] = [];
  
  const logCount = Math.floor(Math.random() * 20) + 5;
  
  for (let i = 0; i < logCount; i++) {
    logs.push({
      id: `log-${prNumber}-${i}`,
      timestamp: new Date(Date.now() - Math.random() * 86400000 * 7).toISOString(),
      level: levels[Math.floor(Math.random() * levels.length)],
      message: `PR #${prNumber}: ${getRandomLogMessage()}`,
      source: sources[Math.floor(Math.random() * sources.length)]
    });
  }
  
  return logs.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());
}

function getRandomLogMessage(): string {
  const messages = [
    'Build completed successfully',
    'Running unit tests...',
    'Deployment initiated',
    'Code quality check passed',
    'Warning: Deprecated API usage detected',
    'Error: Test case failed',
    'Docker image built successfully',
    'Database migration completed',
    'Security scan completed',
    'Performance metrics collected'
  ];
  return messages[Math.floor(Math.random() * messages.length)];
}

function generateMockMetrics(): PRMetrics {
  return {
    buildTime: Math.floor(Math.random() * 300) + 30, // 30-330 seconds
    testCoverage: Math.floor(Math.random() * 40) + 60, // 60-100%
    linesOfCode: Math.floor(Math.random() * 1000) + 100,
    filesChanged: Math.floor(Math.random() * 20) + 1,
    errors: Math.floor(Math.random() * 5),
    warnings: Math.floor(Math.random() * 10),
    deploymentStatus: ['success', 'failed', 'pending', 'in-progress'][Math.floor(Math.random() * 4)] as any
  };
}

function generateMockPRs(repoName: string): PR[] {
  const statuses: ('open' | 'closed' | 'merged')[] = ['open', 'closed', 'merged'];
  const authors = ['alice', 'bob', 'charlie', 'diana', 'eve'];
  const prs: PR[] = [];
  
  const prCount = Math.floor(Math.random() * 15) + 5; // 5-20 PRs
  
  for (let i = 1; i <= prCount; i++) {
    const status = statuses[Math.floor(Math.random() * statuses.length)];
    const metrics = generateMockMetrics();
    
    prs.push({
      id: `pr-${repoName}-${i}`,
      number: i,
      title: `Feature: ${getRandomFeatureName()}`,
      status,
      author: authors[Math.floor(Math.random() * authors.length)],
      createdAt: new Date(Date.now() - Math.random() * 86400000 * 30).toISOString(),
      updatedAt: new Date(Date.now() - Math.random() * 86400000 * 7).toISOString(),
      branch: `feature/branch-${i}`,
      deploymentUrl: status === 'merged' || Math.random() > 0.5 ? 
        `https://deploy-${repoName}-pr${i}.herokuapp.com` : undefined,
      buildTime: metrics.buildTime,
      testCoverage: metrics.testCoverage,
      errors: metrics.errors,
      logs: generateMockLogs(i),
      metrics
    });
  }
  
  return prs.sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime());
}

function getRandomFeatureName(): string {
  const features = [
    'Add user authentication',
    'Implement caching layer',
    'Update API endpoints',
    'Fix memory leak',
    'Optimize database queries',
    'Add monitoring dashboard',
    'Implement rate limiting',
    'Update documentation',
    'Add unit tests',
    'Refactor component structure'
  ];
  return features[Math.floor(Math.random() * features.length)];
}

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ repoName: string }> }
) {
  try {
    const { repoName } = await params;
    
    if (!repoName) {
      return Response.json({
        success: false,
        error: 'Repository name is required'
      }, { status: 400 });
    }

    // Simulate API delay
    await new Promise(resolve => setTimeout(resolve, Math.random() * 1000 + 500));

    const prs = generateMockPRs(repoName);
    const openPRs = prs.filter(pr => pr.status === 'open').length;
    const closedPRs = prs.filter(pr => pr.status === 'closed').length;
    const mergedPRs = prs.filter(pr => pr.status === 'merged').length;

    const repoData: RepoData = {
      repoName,
      totalPRs: prs.length,
      openPRs,
      closedPRs,
      mergedPRs,
      prs
    };

    return Response.json({
      success: true,
      data: repoData
    });

  } catch (error) {
    console.error('Error fetching repo data:', error);
    return Response.json({
      success: false,
      error: 'Internal server error'
    }, { status: 500 });
  }
}