'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Activity, Home, GitBranch } from 'lucide-react';
import { cn } from '@/app/lib/utils';

export default function Navigation() {
  const pathname = usePathname();
  const isRepoPage = pathname !== '/' && pathname !== '/dashboard';
  const currentRepo = isRepoPage ? pathname.slice(1) : null;

  return (
    <nav className="bg-white border-b border-gray-200 sticky top-0 z-10">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link href="/" className="flex items-center space-x-3">
            <Activity className="w-8 h-8 text-blue-600" />
            <span className="text-xl font-bold text-gray-900">PulseCheck</span>
          </Link>

          {/* Navigation Items */}
          <div className="flex items-center space-x-6">
            <Link
              href="/"
              className={cn(
                'flex items-center space-x-2 px-3 py-2 rounded-md text-sm font-medium transition-colors',
                pathname === '/'
                  ? 'bg-blue-100 text-blue-700'
                  : 'text-gray-600 hover:text-gray-900 hover:bg-gray-100'
              )}
            >
              <Home className="w-4 h-4" />
              <span>Dashboard</span>
            </Link>

            {/* Current Repository */}
            {currentRepo && (
              <div className="flex items-center space-x-2 px-3 py-2 bg-gray-100 rounded-md">
                <GitBranch className="w-4 h-4 text-gray-600" />
                <span className="text-sm font-medium text-gray-900">{currentRepo}</span>
              </div>
            )}
          </div>
        </div>
      </div>
    </nav>
  );
}