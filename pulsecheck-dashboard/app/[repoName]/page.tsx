'use client';

import { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';
import { RepoData, ApiResponse } from '@/app/types';
import PRCard from '@/app/components/PRCard';
import MetricsCharts from '@/app/components/MetricsCharts';
import LoadingSpinner, { LoadingSkeleton } from '@/app/components/LoadingSpinner';
import ErrorState from '@/app/components/ErrorState';
import { GitBranch, GitPullRequest, CheckCircle, XCircle, BarChart3, List } from 'lucide-react';

export default function RepoPage() {
  const params = useParams();
  const repoName = params.repoName as string;
  
  const [repoData, setRepoData] = useState<RepoData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeView, setActiveView] = useState<'list' | 'charts'>('list');
  const [filterStatus, setFilterStatus] = useState<'all' | 'open' | 'closed' | 'merged'>('all');

  const fetchRepoData = async () => {
    try {
      setLoading(true);
      setError(null);
      
      const response = await fetch(`/api/repos/${repoName}`);
      const result: ApiResponse<RepoData> = await response.json();
      
      if (!result.success) {
        throw new Error(result.error || 'Failed to fetch repository data');
      }
      
      setRepoData(result.data || null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (repoName) {
      fetchRepoData();
    }
  }, [repoName]);

  if (loading) {
    return (
      <div className="container mx-auto px-4 py-8">
        <LoadingSkeleton />
      </div>
    );
  }

  if (error) {
    return (
      <div className="container mx-auto px-4 py-8">
        <ErrorState message={error} onRetry={fetchRepoData} />
      </div>
    );
  }

  if (!repoData) {
    return (
      <div className="container mx-auto px-4 py-8">
        <ErrorState message="Repository not found" />
      </div>
    );
  }

  const filteredPRs = repoData.prs.filter(pr => {
    if (filterStatus === 'all') return true;
    return pr.status === filterStatus;
  });

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center space-x-3 mb-4">
          <GitBranch className="w-8 h-8 text-blue-600" />
          <h1 className="text-3xl font-bold text-gray-900">{repoData.repoName}</h1>
        </div>
        <p className="text-gray-600">
          Monitor pull requests, logs, and metrics for your repository
        </p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Total PRs</p>
              <p className="text-2xl font-bold text-gray-900">{repoData.totalPRs}</p>
            </div>
            <GitPullRequest className="w-8 h-8 text-gray-400" />
          </div>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Open PRs</p>
              <p className="text-2xl font-bold text-blue-600">{repoData.openPRs}</p>
            </div>
            <GitPullRequest className="w-8 h-8 text-blue-400" />
          </div>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Merged PRs</p>
              <p className="text-2xl font-bold text-green-600">{repoData.mergedPRs}</p>
            </div>
            <CheckCircle className="w-8 h-8 text-green-400" />
          </div>
        </div>
        
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600">Closed PRs</p>
              <p className="text-2xl font-bold text-gray-600">{repoData.closedPRs}</p>
            </div>
            <XCircle className="w-8 h-8 text-gray-400" />
          </div>
        </div>
      </div>

      {/* Controls */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-6 space-y-4 sm:space-y-0">
        {/* Filter */}
        <div className="flex items-center space-x-4">
          <label className="text-sm font-medium text-gray-700">Filter:</label>
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value as any)}
            className="px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="all">All PRs</option>
            <option value="open">Open</option>
            <option value="merged">Merged</option>
            <option value="closed">Closed</option>
          </select>
          <span className="text-sm text-gray-500">
            ({filteredPRs.length} {filteredPRs.length === 1 ? 'PR' : 'PRs'})
          </span>
        </div>

        {/* View Toggle */}
        <div className="flex items-center space-x-2 bg-gray-100 rounded-lg p-1">
          <button
            onClick={() => setActiveView('list')}
            className={`flex items-center space-x-2 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
              activeView === 'list'
                ? 'bg-white text-gray-900 shadow-sm'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            <List className="w-4 h-4" />
            <span>List View</span>
          </button>
          <button
            onClick={() => setActiveView('charts')}
            className={`flex items-center space-x-2 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
              activeView === 'charts'
                ? 'bg-white text-gray-900 shadow-sm'
                : 'text-gray-600 hover:text-gray-900'
            }`}
          >
            <BarChart3 className="w-4 h-4" />
            <span>Charts</span>
          </button>
        </div>
      </div>

      {/* Content */}
      {activeView === 'list' ? (
        <div className="space-y-6">
          {filteredPRs.length === 0 ? (
            <div className="text-center py-12">
              <GitPullRequest className="w-16 h-16 text-gray-300 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">No pull requests found</h3>
              <p className="text-gray-500">
                {filterStatus === 'all' 
                  ? 'This repository doesn\'t have any pull requests yet.'
                  : `No ${filterStatus} pull requests found.`
                }
              </p>
            </div>
          ) : (
            filteredPRs.map((pr) => (
              <PRCard key={pr.id} pr={pr} />
            ))
          )}
        </div>
      ) : (
        <MetricsCharts prs={repoData.prs} />
      )}
    </div>
  );
}