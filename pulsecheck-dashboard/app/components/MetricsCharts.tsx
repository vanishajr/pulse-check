'use client';

import { PR } from '@/app/types';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, LineChart, Line, PieChart, Pie, Cell } from 'recharts';

interface MetricsChartsProps {
  prs: PR[];
}

export default function MetricsCharts({ prs }: MetricsChartsProps) {
  // Prepare data for build time chart
  const buildTimeData = prs.slice(0, 10).map(pr => ({
    name: `PR #${pr.number}`,
    buildTime: pr.metrics.buildTime,
    testCoverage: pr.metrics.testCoverage,
    errors: pr.metrics.errors
  }));

  // Prepare data for status distribution
  const statusData = [
    { name: 'Open', value: prs.filter(pr => pr.status === 'open').length, color: '#3B82F6' },
    { name: 'Closed', value: prs.filter(pr => pr.status === 'closed').length, color: '#6B7280' },
    { name: 'Merged', value: prs.filter(pr => pr.status === 'merged').length, color: '#10B981' }
  ].filter(item => item.value > 0);

  // Prepare data for deployment status
  const deploymentStatusData = [
    { name: 'Success', value: prs.filter(pr => pr.metrics.deploymentStatus === 'success').length, color: '#10B981' },
    { name: 'Failed', value: prs.filter(pr => pr.metrics.deploymentStatus === 'failed').length, color: '#EF4444' },
    { name: 'Pending', value: prs.filter(pr => pr.metrics.deploymentStatus === 'pending').length, color: '#F59E0B' },
    { name: 'In Progress', value: prs.filter(pr => pr.metrics.deploymentStatus === 'in-progress').length, color: '#3B82F6' }
  ].filter(item => item.value > 0);

  return (
    <div className="space-y-8">
      {/* Build Time & Test Coverage Chart */}
      <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Build Time & Test Coverage</h3>
        <div className="h-80">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={buildTimeData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis 
                dataKey="name" 
                tick={{ fontSize: 12 }}
                angle={-45}
                textAnchor="end"
                height={80}
              />
              <YAxis yAxisId="left" tick={{ fontSize: 12 }} />
              <YAxis yAxisId="right" orientation="right" tick={{ fontSize: 12 }} />
              <Tooltip 
                formatter={(value: any, name: string) => [
                  name === 'buildTime' ? `${value}s` : 
                  name === 'testCoverage' ? `${value}%` : value,
                  name === 'buildTime' ? 'Build Time' :
                  name === 'testCoverage' ? 'Test Coverage' : name
                ]}
              />
              <Bar yAxisId="left" dataKey="buildTime" fill="#3B82F6" name="Build Time" />
              <Bar yAxisId="right" dataKey="testCoverage" fill="#10B981" name="Test Coverage" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Error Trends Chart */}
      <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Error Trends</h3>
        <div className="h-80">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={buildTimeData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis 
                dataKey="name" 
                tick={{ fontSize: 12 }}
                angle={-45}
                textAnchor="end"
                height={80}
              />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip 
                formatter={(value: any) => [value, 'Errors']}
              />
              <Line 
                type="monotone" 
                dataKey="errors" 
                stroke="#EF4444" 
                strokeWidth={2}
                dot={{ fill: '#EF4444', r: 4 }}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* PR Status Distribution */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">PR Status Distribution</h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={statusData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }) => `${name} (${(percent * 100).toFixed(0)}%)`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {statusData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Deployment Status Distribution */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900 mb-4">Deployment Status</h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={deploymentStatusData}
                  cx="50%"
                  cy="50%"
                  labelLine={false}
                  label={({ name, percent }) => `${name} (${(percent * 100).toFixed(0)}%)`}
                  outerRadius={80}
                  fill="#8884d8"
                  dataKey="value"
                >
                  {deploymentStatusData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
}