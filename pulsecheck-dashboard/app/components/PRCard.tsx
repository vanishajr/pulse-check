'use client';

import { useState } from 'react';
import { PR, LogEntry } from '@/app/types';
import { cn, formatDate, formatDuration, getStatusColor, getLogLevelColor } from '@/app/lib/utils';
import { ChevronDown, ChevronRight, ExternalLink, GitPullRequest, Clock, TestTube, AlertCircle, CheckCircle, XCircle } from 'lucide-react';

interface PRCardProps {
  pr: PR;
}

export default function PRCard({ pr }: PRCardProps) {
  const [isExpanded, setIsExpanded] = useState(false);
  const [activeTab, setActiveTab] = useState<'logs' | 'metrics'>('logs');

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'open':
        return <GitPullRequest className="w-4 h-4 text-blue-600" />;
      case 'merged':
        return <CheckCircle className="w-4 h-4 text-green-600" />;
      case 'closed':
        return <XCircle className="w-4 h-4 text-gray-600" />;
      default:
        return <GitPullRequest className="w-4 h-4" />;
    }
  };

  const getDeploymentStatusIcon = (status: string) => {
    switch (status) {
      case 'success':
        return <CheckCircle className="w-4 h-4 text-green-600" />;
      case 'failed':
        return <XCircle className="w-4 h-4 text-red-600" />;
      case 'pending':
        return <Clock className="w-4 h-4 text-yellow-600" />;
      case 'in-progress':
        return <Clock className="w-4 h-4 text-blue-600 animate-spin" />;
      default:
        return <AlertCircle className="w-4 h-4 text-gray-600" />;
    }
  };

  return (
    <div className="border border-gray-200 rounded-lg bg-white shadow-sm hover:shadow-md transition-shadow">
      <div className="p-6">
        {/* Header */}
        <div className="flex items-start justify-between">
          <div className="flex items-start space-x-3 flex-1">
            {getStatusIcon(pr.status)}
            <div className="flex-1 min-w-0">
              <div className="flex items-center space-x-3 mb-2">
                <h3 className="text-lg font-semibold text-gray-900 truncate">
                  {pr.title}
                </h3>
                <span className={cn(
                  'px-2 py-1 text-xs font-medium rounded-full border',
                  getStatusColor(pr.status)
                )}>
                  {pr.status}
                </span>
              </div>
              <div className="flex items-center space-x-4 text-sm text-gray-600">
                <span>#{pr.number}</span>
                <span>by {pr.author}</span>
                <span>{formatDate(pr.createdAt)}</span>
                <span className="text-gray-400">•</span>
                <span>{pr.branch}</span>
              </div>
            </div>
          </div>
          <button
            onClick={() => setIsExpanded(!isExpanded)}
            className="ml-4 p-1 rounded-md hover:bg-gray-100 transition-colors"
          >
            {isExpanded ? (
              <ChevronDown className="w-5 h-5 text-gray-500" />
            ) : (
              <ChevronRight className="w-5 h-5 text-gray-500" />
            )}
          </button>
        </div>

        {/* Quick Stats */}
        <div className="flex items-center space-x-6 mt-4 text-sm">
          <div className="flex items-center space-x-1">
            <Clock className="w-4 h-4 text-gray-500" />
            <span>Build: {formatDuration(pr.buildTime || 0)}</span>
          </div>
          <div className="flex items-center space-x-1">
            <TestTube className="w-4 h-4 text-gray-500" />
            <span>Coverage: {pr.testCoverage || 0}%</span>
          </div>
          <div className="flex items-center space-x-1">
            <AlertCircle className="w-4 h-4 text-gray-500" />
            <span>Errors: {pr.errors}</span>
          </div>
          <div className="flex items-center space-x-1">
            {getDeploymentStatusIcon(pr.metrics.deploymentStatus)}
            <span className="capitalize">{pr.metrics.deploymentStatus}</span>
          </div>
        </div>

        {/* Deployment Link */}
        {pr.deploymentUrl && (
          <div className="mt-4">
            <a
              href={pr.deploymentUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center space-x-2 text-blue-600 hover:text-blue-800 text-sm font-medium"
            >
              <ExternalLink className="w-4 h-4" />
              <span>View Deployment</span>
            </a>
          </div>
        )}
      </div>

      {/* Expanded Content */}
      {isExpanded && (
        <div className="border-t border-gray-200">
          {/* Tabs */}
          <div className="flex border-b border-gray-200">
            <button
              onClick={() => setActiveTab('logs')}
              className={cn(
                'px-6 py-3 text-sm font-medium border-b-2 transition-colors',
                activeTab === 'logs'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              )}
            >
              Logs ({pr.logs.length})
            </button>
            <button
              onClick={() => setActiveTab('metrics')}
              className={cn(
                'px-6 py-3 text-sm font-medium border-b-2 transition-colors',
                activeTab === 'metrics'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              )}
            >
              Metrics
            </button>
          </div>

          {/* Tab Content */}
          <div className="p-6">
            {activeTab === 'logs' && (
              <div className="space-y-3">
                <h4 className="text-sm font-medium text-gray-900">Recent Logs</h4>
                <div className="max-h-64 overflow-y-auto space-y-2">
                  {pr.logs.slice(0, 10).map((log) => (
                    <div key={log.id} className="flex items-start space-x-3 p-2 rounded-md bg-gray-50">
                      <span className="text-xs text-gray-500 mt-1 whitespace-nowrap">
                        {formatDate(log.timestamp)}
                      </span>
                      <span className={cn('text-xs font-medium mt-1', getLogLevelColor(log.level))}>
                        {log.level.toUpperCase()}
                      </span>
                      <span className="text-sm text-gray-800 flex-1">{log.message}</span>
                      {log.source && (
                        <span className="text-xs text-gray-500 bg-gray-200 px-2 py-1 rounded">
                          {log.source}
                        </span>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}

            {activeTab === 'metrics' && (
              <div className="space-y-4">
                <h4 className="text-sm font-medium text-gray-900">Detailed Metrics</h4>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  <div className="bg-gray-50 p-3 rounded-md">
                    <div className="text-xs text-gray-500">Build Time</div>
                    <div className="text-lg font-semibold">{formatDuration(pr.metrics.buildTime)}</div>
                  </div>
                  <div className="bg-gray-50 p-3 rounded-md">
                    <div className="text-xs text-gray-500">Test Coverage</div>
                    <div className="text-lg font-semibold">{pr.metrics.testCoverage}%</div>
                  </div>
                  <div className="bg-gray-50 p-3 rounded-md">
                    <div className="text-xs text-gray-500">Lines of Code</div>
                    <div className="text-lg font-semibold">{pr.metrics.linesOfCode.toLocaleString()}</div>
                  </div>
                  <div className="bg-gray-50 p-3 rounded-md">
                    <div className="text-xs text-gray-500">Files Changed</div>
                    <div className="text-lg font-semibold">{pr.metrics.filesChanged}</div>
                  </div>
                  <div className="bg-gray-50 p-3 rounded-md">
                    <div className="text-xs text-gray-500">Errors</div>
                    <div className="text-lg font-semibold text-red-600">{pr.metrics.errors}</div>
                  </div>
                  <div className="bg-gray-50 p-3 rounded-md">
                    <div className="text-xs text-gray-500">Warnings</div>
                    <div className="text-lg font-semibold text-yellow-600">{pr.metrics.warnings}</div>
                  </div>
                  <div className="bg-gray-50 p-3 rounded-md">
                    <div className="text-xs text-gray-500">Status</div>
                    <div className={cn(
                      'text-sm font-semibold capitalize',
                      pr.metrics.deploymentStatus === 'success' ? 'text-green-600' :
                      pr.metrics.deploymentStatus === 'failed' ? 'text-red-600' :
                      pr.metrics.deploymentStatus === 'pending' ? 'text-yellow-600' :
                      'text-blue-600'
                    )}>
                      {pr.metrics.deploymentStatus}
                    </div>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}