export interface PR {
  id: string;
  number: number;
  title: string;
  status: 'open' | 'closed' | 'merged';
  author: string;
  createdAt: string;
  updatedAt: string;
  branch: string;
  deploymentUrl?: string;
  buildTime?: number;
  testCoverage?: number;
  errors: number;
  logs: LogEntry[];
  metrics: PRMetrics;
}

export interface LogEntry {
  id: string;
  timestamp: string;
  level: 'info' | 'warn' | 'error' | 'debug';
  message: string;
  source?: string;
}

export interface PRMetrics {
  buildTime: number; // in seconds
  testCoverage: number; // percentage
  linesOfCode: number;
  filesChanged: number;
  errors: number;
  warnings: number;
  deploymentStatus: 'success' | 'failed' | 'pending' | 'in-progress';
}

export interface RepoData {
  repoName: string;
  totalPRs: number;
  openPRs: number;
  closedPRs: number;
  mergedPRs: number;
  prs: PR[];
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}