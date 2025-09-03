import Link from 'next/link';
import { GitBranch, ExternalLink, TrendingUp, Activity } from 'lucide-react';

const mockRepos = [
  { name: 'frontend-app', description: 'Main frontend application', prs: 12, lastActivity: '2 hours ago' },
  { name: 'backend-api', description: 'REST API backend service', prs: 8, lastActivity: '4 hours ago' },
  { name: 'mobile-app', description: 'React Native mobile application', prs: 5, lastActivity: '1 day ago' },
  { name: 'auth-service', description: 'Authentication microservice', prs: 3, lastActivity: '2 days ago' },
  { name: 'data-pipeline', description: 'ETL data processing pipeline', prs: 7, lastActivity: '6 hours ago' },
  { name: 'ui-components', description: 'Shared component library', prs: 15, lastActivity: '30 minutes ago' }
];

export default function Home() {
  return (
    <div className="min-h-screen bg-gray-50">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <div className="text-center mb-12">
          <div className="flex items-center justify-center space-x-3 mb-4">
            <Activity className="w-12 h-12 text-blue-600" />
            <h1 className="text-4xl font-bold text-gray-900">PulseCheck Dashboard</h1>
          </div>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Monitor your repositories, track pull requests, and analyze metrics in real-time
          </p>
        </div>

        {/* Stats Overview */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Total Repositories</p>
                <p className="text-3xl font-bold text-gray-900">{mockRepos.length}</p>
              </div>
              <GitBranch className="w-10 h-10 text-blue-400" />
            </div>
          </div>
          
          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Active Pull Requests</p>
                <p className="text-3xl font-bold text-blue-600">
                  {mockRepos.reduce((sum, repo) => sum + repo.prs, 0)}
                </p>
              </div>
              <TrendingUp className="w-10 h-10 text-green-400" />
            </div>
          </div>
          
          <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Most Active</p>
                <p className="text-lg font-bold text-green-600">
                  {mockRepos.reduce((max, repo) => repo.prs > max.prs ? repo : max, mockRepos[0]).name}
                </p>
              </div>
              <Activity className="w-10 h-10 text-purple-400" />
            </div>
          </div>
        </div>

        {/* Repository List */}
        <div className="mb-8">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">Your Repositories</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {mockRepos.map((repo) => (
              <Link
                key={repo.name}
                href={`/${repo.name}`}
                className="group bg-white p-6 rounded-lg shadow-sm border border-gray-200 hover:shadow-md hover:border-blue-300 transition-all duration-200"
              >
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-center space-x-3">
                    <GitBranch className="w-6 h-6 text-blue-600" />
                    <h3 className="text-lg font-semibold text-gray-900 group-hover:text-blue-600 transition-colors">
                      {repo.name}
                    </h3>
                  </div>
                  <ExternalLink className="w-4 h-4 text-gray-400 group-hover:text-blue-600 transition-colors" />
                </div>
                
                <p className="text-gray-600 mb-4 text-sm">{repo.description}</p>
                
                <div className="flex items-center justify-between text-sm">
                  <div className="flex items-center space-x-4">
                    <span className="text-gray-500">
                      <span className="font-medium text-blue-600">{repo.prs}</span> PRs
                    </span>
                    <span className="text-gray-500">Last: {repo.lastActivity}</span>
                  </div>
                  <div className="flex items-center space-x-1 text-blue-600 font-medium">
                    <span>View Details</span>
                    <ExternalLink className="w-3 h-3" />
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </div>

        {/* Quick Actions */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <button className="p-4 text-left border border-gray-200 rounded-lg hover:border-blue-300 hover:bg-blue-50 transition-colors">
              <div className="text-sm font-medium text-gray-900 mb-1">Add New Repository</div>
              <div className="text-xs text-gray-500">Connect a new repository to monitor</div>
            </button>
            <button className="p-4 text-left border border-gray-200 rounded-lg hover:border-blue-300 hover:bg-blue-50 transition-colors">
              <div className="text-sm font-medium text-gray-900 mb-1">View All Metrics</div>
              <div className="text-xs text-gray-500">Analyze performance across all repos</div>
            </button>
            <button className="p-4 text-left border border-gray-200 rounded-lg hover:border-blue-300 hover:bg-blue-50 transition-colors">
              <div className="text-sm font-medium text-gray-900 mb-1">Configure Alerts</div>
              <div className="text-xs text-gray-500">Set up notifications for key events</div>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
