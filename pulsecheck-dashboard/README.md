# PulseCheck Dashboard

A modern Next.js dashboard for monitoring repositories, tracking pull requests, and analyzing metrics in real-time.

## 🚀 Features

- **Dynamic Repository Routing**: Access any repository via `/repo-name` URLs
- **Real-time Data**: Mock API endpoints that simulate real repository data
- **Interactive PR Cards**: Expandable cards showing logs, metrics, and deployment info
- **Charts & Visualizations**: Built with Recharts for metrics visualization
- **Responsive Design**: Mobile-friendly design with Tailwind CSS
- **Loading & Error States**: Proper handling of loading and error scenarios

## 📁 Project Structure

```
pulsecheck-dashboard/
├── app/
│   ├── [repoName]/          # Dynamic repository pages
│   │   └── page.tsx         # Main repository dashboard
│   ├── api/
│   │   └── repos/
│   │       └── [repoName]/
│   │           └── route.ts # API endpoint for repository data
│   ├── components/          # Reusable components
│   │   ├── PRCard.tsx       # Pull request card component
│   │   ├── MetricsCharts.tsx # Charts for metrics visualization
│   │   ├── Navigation.tsx   # App navigation
│   │   ├── LoadingSpinner.tsx # Loading states
│   │   └── ErrorState.tsx   # Error handling
│   ├── lib/
│   │   └── utils.ts         # Utility functions
│   ├── types/
│   │   └── index.ts         # TypeScript type definitions
│   ├── layout.tsx           # Root layout
│   ├── page.tsx             # Home page
│   └── globals.css          # Global styles
└── package.json
```

## 🛠 Technology Stack

- **Next.js 15**: React framework with App Router
- **TypeScript**: Type safety
- **Tailwind CSS 4**: Styling and responsive design
- **Recharts**: Chart library for data visualization
- **Lucide React**: Icon library
- **clsx**: Conditional styling utility

## 📊 Dashboard Features

### Repository Overview
- Total PRs, Open PRs, Merged PRs, Closed PRs statistics
- Quick access to repository actions
- Real-time activity indicators

### Pull Request Management
- **List View**: Comprehensive PR cards with expandable details
- **Charts View**: Visual analytics and metrics
- **Filtering**: Filter PRs by status (all, open, closed, merged)
- **PR Details**: Logs, metrics, deployment links for each PR

### Metrics & Analytics
- Build time tracking
- Test coverage monitoring
- Error and warning counts
- Deployment status tracking
- Interactive charts for trend analysis

## 🔧 API Structure

### GET `/api/repos/[repoName]`

Returns comprehensive repository data including:

```json
{
  "success": true,
  "data": {
    "repoName": "example-repo",
    "totalPRs": 15,
    "openPRs": 3,
    "closedPRs": 7,
    "mergedPRs": 5,
    "prs": [
      {
        "id": "pr-1",
        "number": 1,
        "title": "Feature: Add user authentication",
        "status": "open",
        "author": "developer",
        "createdAt": "2024-01-15T10:00:00Z",
        "branch": "feature/auth",
        "deploymentUrl": "https://deploy-example.com",
        "buildTime": 120,
        "testCoverage": 85,
        "errors": 0,
        "logs": [...],
        "metrics": {...}
      }
    ]
  }
}
```

## 🚀 Getting Started

1. **Install Dependencies**:
   ```bash
   npm install
   ```

2. **Run Development Server**:
   ```bash
   npm run dev
   ```

3. **Access the Dashboard**:
   - Home: `http://localhost:3000`
   - Repository pages: `http://localhost:3000/[repo-name]`

## 🎯 Usage Examples

### Accessing Repository Dashboards
- `http://localhost:3000/frontend-app` - Frontend application dashboard
- `http://localhost:3000/backend-api` - Backend API dashboard
- `http://localhost:3000/mobile-app` - Mobile app dashboard

### Navigation
- Click on repository cards from the home page
- Use the navigation bar to return to the dashboard
- Current repository is displayed in the navigation

## 🔧 Customization

### Adding Real Data
Replace the mock data generator in `/api/repos/[repoName]/route.ts` with real API calls to your backend services.

### Styling
Modify `tailwind.config.js` and component styles to match your brand colors and design system.

### Charts
Extend `MetricsCharts.tsx` to add more chart types and metrics visualization.

## 📝 Component Architecture

### PRCard Component
- Expandable design with tabs for logs and metrics
- Real-time status indicators
- Deployment link integration
- Responsive layout

### MetricsCharts Component
- Build time and test coverage bar charts
- Error trends line chart
- Status distribution pie charts
- Responsive chart containers

### Navigation Component
- Dynamic repository detection
- Active state management
- Responsive design

This dashboard provides a solid foundation for monitoring repository metrics and can be easily extended with additional features as needed.