import React from 'react';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';
import { Bar } from 'react-chartjs-2';

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend
);

const Chart = ({ cdrs, loading = false }) => {
  // Process CDR data to count calls per caller
  const processCallerData = () => {
    const callerCounts = {};
    cdrs.forEach(cdr => {
      callerCounts[cdr.caller] = (callerCounts[cdr.caller] || 0) + 1;
    });

    // Sort by count and take top 10
    const sortedCallers = Object.entries(callerCounts)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 10);

    return {
      labels: sortedCallers.map(([caller]) => caller),
      counts: sortedCallers.map(([, count]) => count)
    };
  };

  const { labels, counts } = processCallerData();

  const chartData = {
    labels,
    datasets: [
      {
        label: 'Number of Calls',
        data: counts,
        backgroundColor: 'rgba(59, 130, 246, 0.5)',
        borderColor: 'rgba(59, 130, 246, 1)',
        borderWidth: 1,
      },
    ],
  };

  const options = {
    responsive: true,
    plugins: {
      legend: {
        position: 'top',
      },
      title: {
        display: true,
        text: 'Calls per Caller (Top 10)',
      },
    },
    scales: {
      y: {
        beginAtZero: true,
        ticks: {
          stepSize: 1,
        },
      },
    },
  };

  if (loading) {
    return (
      <div className="card">
        <div className="card-header">
          <h2 className="text-xl font-semibold text-gray-900">Call Analytics</h2>
        </div>
        <div className="h-64 bg-gray-200 rounded animate-pulse"></div>
      </div>
    );
  }

  if (cdrs.length === 0) {
    return (
      <div className="card">
        <div className="card-header">
          <h2 className="text-xl font-semibold text-gray-900">Call Analytics</h2>
        </div>
        <div className="text-center py-8 text-gray-500">
          <p className="text-lg">📊</p>
          <p className="text-sm">No data available for analytics</p>
        </div>
      </div>
    );
  }

  return (
    <div className="card">
      <div className="card-header">
        <h2 className="text-xl font-semibold text-gray-900">Call Analytics</h2>
      </div>
      <div className="h-64">
        <Bar data={chartData} options={options} />
      </div>
    </div>
  );
};

export default Chart;
