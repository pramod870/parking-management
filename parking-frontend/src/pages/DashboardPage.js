// src/pages/DashboardPage.js
import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { dashboardAPI, sessionsAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from 'recharts';

const COLORS = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6'];

export default function DashboardPage() {
  const { isAdmin, isOperator, user } = useAuth();
  const [stats, setStats]         = useState(null);
  const [revenue, setRevenue]     = useState(null);
  const [sessions, setSessions]   = useState([]);
  const [loading, setLoading]     = useState(true);

  useEffect(() => {
    const load = async () => {
      try {
        const [sessRes] = await Promise.all([
          isOperator() ? sessionsAPI.list() : Promise.resolve({ data: [] }),
        ]);
        setSessions(sessRes.data || []);

        if (isAdmin()) {
          const [statsRes, revRes] = await Promise.all([
            dashboardAPI.stats(),
            dashboardAPI.revenue(
              new Date(Date.now() - 30 * 86400000).toISOString().split('T')[0],
              new Date().toISOString().split('T')[0]
            ),
          ]);
          setStats(statsRes.data);
          setRevenue(revRes.data);
        }
      } catch (e) {
        console.error(e);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, []);

  if (loading) return (
    <div className="loading-screen" style={{ height: '60vh' }}>
      <div className="spinner" />
    </div>
  );

  // Slot utilization for pie chart
  const utilData = stats?.slot_utilization
    ? Object.values(
        (stats.slot_utilization || []).reduce((acc, row) => {
          const k = row.vehicleType || row.vehicle_type;
          if (!acc[k]) acc[k] = { name: k, available: 0, occupied: 0 };
          const s = row.status;
          const c = parseInt(row.count);
          if (s === 'available') acc[k].available += c;
          if (s === 'occupied')  acc[k].occupied  += c;
          return acc;
        }, {})
      )
    : [];

  const vehicleBreakdown = (stats?.vehicle_type_breakdown || []).map(v => ({
    name: v.vehicleType || v.vehicle_type,
    value: parseInt(v.total),
  }));

  const dailyRevenue = (revenue?.daily_breakdown || []).map(d => ({
    date: d.date ? d.date.split('-').slice(1).join('/') : '',
    revenue: parseFloat(d.revenue || 0),
    count: parseInt(d.count || 0),
  })).slice(-14);

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Dashboard</h1>
          <p className="page-subtitle">Welcome back, {user?.name} 👋</p>
        </div>
        {isOperator() && (
          <Link to="/entry-exit" className="btn btn-primary">+ Vehicle Entry</Link>
        )}
      </div>

      {/* Admin stats */}
      {isAdmin() && stats && (
        <>
          <div className="stats-grid">
            <div className="stat-card green">
              <div className="stat-label">Total Revenue</div>
              <div className="stat-value">₹{parseFloat(stats.total_revenue || 0).toLocaleString('en-IN')}</div>
              <div className="stat-sub">All time</div>
            </div>
            <div className="stat-card blue">
              <div className="stat-label">Today's Revenue</div>
              <div className="stat-value">₹{parseFloat(stats.today_revenue || 0).toLocaleString('en-IN')}</div>
              <div className="stat-sub">Today</div>
            </div>
            <div className="stat-card yellow">
              <div className="stat-label">Active Sessions</div>
              <div className="stat-value">{stats.active_sessions || 0}</div>
              <div className="stat-sub">Currently parked</div>
            </div>
            <div className="stat-card red">
              <div className="stat-label">Sessions Today</div>
              <div className="stat-value">{stats.total_sessions_today || 0}</div>
              <div className="stat-sub">Vehicles served</div>
            </div>
          </div>

          <div className="two-col" style={{ marginBottom: 24 }}>
            {/* Revenue chart */}
            <div className="card">
              <div style={{ fontWeight: 700, marginBottom: 16 }}>Daily Revenue (Last 14 Days)</div>
              {dailyRevenue.length > 0 ? (
                <ResponsiveContainer width="100%" height={200}>
                  <BarChart data={dailyRevenue}>
                    <XAxis dataKey="date" tick={{ fill: 'var(--text3)', fontSize: 11 }} />
                    <YAxis tick={{ fill: 'var(--text3)', fontSize: 11 }} />
                    <Tooltip
                      contentStyle={{ background: 'var(--surface2)', border: '1px solid var(--border)', borderRadius: 8 }}
                      labelStyle={{ color: 'var(--text)' }}
                      formatter={v => [`₹${v.toLocaleString('en-IN')}`, 'Revenue']}
                    />
                    <Bar dataKey="revenue" fill="var(--accent)" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              ) : (
                <div className="empty-state"><div className="empty-text">No revenue data yet</div></div>
              )}
            </div>

            {/* Vehicle type pie */}
            <div className="card">
              <div style={{ fontWeight: 700, marginBottom: 16 }}>Active by Vehicle Type</div>
              {vehicleBreakdown.length > 0 ? (
                <ResponsiveContainer width="100%" height={200}>
                  <PieChart>
                    <Pie data={vehicleBreakdown} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={70} label>
                      {vehicleBreakdown.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                    </Pie>
                    <Legend />
                    <Tooltip contentStyle={{ background: 'var(--surface2)', border: '1px solid var(--border)', borderRadius: 8 }} />
                  </PieChart>
                </ResponsiveContainer>
              ) : (
                <div className="empty-state"><div className="empty-text">No active sessions</div></div>
              )}
            </div>
          </div>

          {/* Slot utilization */}
          {utilData.length > 0 && (
            <div className="card" style={{ marginBottom: 24 }}>
              <div style={{ fontWeight: 700, marginBottom: 16 }}>Slot Utilization by Type</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                {utilData.map(row => {
                  const total = row.available + row.occupied;
                  const pct   = total > 0 ? Math.round(row.occupied / total * 100) : 0;
                  const color = pct > 80 ? 'var(--accent4)' : pct > 50 ? 'var(--accent3)' : 'var(--accent2)';
                  return (
                    <div key={row.name}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13, marginBottom: 4 }}>
                        <span style={{ textTransform: 'capitalize', fontWeight: 600 }}>{row.name}</span>
                        <span style={{ color: 'var(--text2)' }}>
                          {row.occupied}/{total} occupied
                          <span className="badge badge-gray" style={{ marginLeft: 8, fontSize: 10 }}>{pct}%</span>
                        </span>
                      </div>
                      <div className="progress-wrap">
                        <div className="progress-bar" style={{ width: `${pct}%`, background: color }} />
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </>
      )}

      {/* Active sessions table (operator+) */}
      {isOperator() && (
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <div style={{ fontWeight: 700 }}>Active Sessions ({sessions.length})</div>
            <Link to="/sessions" className="btn btn-ghost btn-sm">View All →</Link>
          </div>
          {sessions.length === 0 ? (
            <div className="empty-state">
              <div className="empty-icon">🚗</div>
              <div className="empty-text">No active sessions</div>
            </div>
          ) : (
            <div className="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Vehicle</th><th>Type</th><th>Lot / Slot</th><th>Entry Time</th><th>Duration</th><th>Action</th>
                  </tr>
                </thead>
                <tbody>
                  {sessions.slice(0, 8).map(s => {
                    const mins = s.duration_minutes || Math.round((Date.now() - new Date(s.entry_time)) / 60000);
                    return (
                      <tr key={s.id}>
                        <td><span className="mono">{s.vehicle_number}</span></td>
                        <td><span className="badge badge-blue">{s.vehicle_type}</span></td>
                        <td>{s.parking_lot} / <strong>{s.slot_number}</strong></td>
                        <td style={{ color: 'var(--text2)', fontSize: 13 }}>
                          {new Date(s.entry_time).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' })}
                        </td>
                        <td>
                          <span className="badge badge-yellow">{Math.floor(mins/60)}h {mins%60}m</span>
                        </td>
                        <td>
                          <Link to="/entry-exit" className="btn btn-danger btn-sm">Exit</Link>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* Non-operator user */}
      {!isOperator() && (
        <div className="two-col">
          <div className="card">
            <div style={{ fontSize: 32, marginBottom: 12 }}>🅿️</div>
            <div style={{ fontWeight: 700, fontSize: 18, marginBottom: 8 }}>Find Parking</div>
            <p style={{ color: 'var(--text2)', fontSize: 14, marginBottom: 16 }}>Browse available parking lots and check slot availability in real-time.</p>
            <Link to="/lots" className="btn btn-primary">Browse Lots →</Link>
          </div>
          <div className="card">
            <div style={{ fontSize: 32, marginBottom: 12 }}>📅</div>
            <div style={{ fontWeight: 700, fontSize: 18, marginBottom: 8 }}>My Bookings</div>
            <p style={{ color: 'var(--text2)', fontSize: 14, marginBottom: 16 }}>View and manage your parking reservations. Cancel if needed.</p>
            <Link to="/bookings" className="btn btn-ghost">View Bookings →</Link>
          </div>
        </div>
      )}
    </div>
  );
}
