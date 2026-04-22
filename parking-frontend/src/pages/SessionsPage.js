// src/pages/SessionsPage.js
import React, { useState, useEffect } from 'react';
import { sessionsAPI } from '../services/api';
import { Link } from 'react-router-dom';

export default function SessionsPage() {
  const [sessions, setSessions] = useState([]);
  const [loading, setLoading]   = useState(true);

  const load = async () => {
    setLoading(true);
    try { const r = await sessionsAPI.list(); setSessions(r.data || []); }
    catch (e) { console.error(e); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const getMins = (entryTime) => Math.round((Date.now() - new Date(entryTime)) / 60000);

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Active Sessions</h1>
          <p className="page-subtitle">{sessions.length} vehicles currently parked</p>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button onClick={load} className="btn btn-ghost btn-sm">↺ Refresh</button>
          <Link to="/entry-exit" className="btn btn-primary">+ New Entry</Link>
        </div>
      </div>

      <div className="card">
        {loading ? (
          <div className="loading-screen" style={{ height: '40vh' }}><div className="spinner" /></div>
        ) : sessions.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">🚗</div>
            <div className="empty-text">No active sessions</div>
            <div className="empty-sub">No vehicles are currently parked</div>
          </div>
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>ID</th><th>Vehicle</th><th>Type</th>
                  <th>Lot / Slot</th><th>Floor</th><th>Entry</th><th>Duration</th><th>Action</th>
                </tr>
              </thead>
              <tbody>
                {sessions.map(s => {
                  const mins = getMins(s.entry_time);
                  return (
                    <tr key={s.id}>
                      <td><span className="badge badge-gray">#{s.id}</span></td>
                      <td><span className="mono" style={{ fontWeight: 600 }}>{s.vehicle_number}</span></td>
                      <td>
                        <span className={`badge ${s.vehicle_type === 'car' ? 'badge-blue' : s.vehicle_type === 'bike' ? 'badge-green' : 'badge-yellow'}`}>
                          {s.vehicle_type}
                        </span>
                      </td>
                      <td>{s.parking_lot} / <strong>{s.slot_number}</strong></td>
                      <td>F{s.floor}</td>
                      <td style={{ color: 'var(--text2)', fontSize: 13 }}>
                        {new Date(s.entry_time).toLocaleString('en-IN', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })}
                      </td>
                      <td><span className="badge badge-yellow">{Math.floor(mins/60)}h {mins%60}m</span></td>
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
    </div>
  );
}
