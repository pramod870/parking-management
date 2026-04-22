// src/pages/LotsPage.js
import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { lotsAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';

function LotCard({ lot, onDelete, isAdmin }) {
  const pct = lot.total_slots > 0 ? Math.round((lot.total_slots - lot.available_slots) / lot.total_slots * 100) : 0;
  const color = pct > 80 ? 'var(--accent4)' : pct > 50 ? 'var(--accent3)' : 'var(--accent2)';

  return (
    <div className="card" style={{ cursor: 'pointer' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 14 }}>
        <div>
          <div style={{ fontWeight: 700, fontSize: 16, marginBottom: 4 }}>{lot.name}</div>
          <div style={{ fontSize: 12, color: 'var(--text3)' }}>📍 {lot.location}</div>
        </div>
        <span className={`badge ${lot.is_active ? 'badge-green' : 'badge-red'}`}>
          {lot.is_active ? 'Active' : 'Inactive'}
        </span>
      </div>

      <div style={{ display: 'flex', gap: 16, marginBottom: 14 }}>
        <div style={{ flex: 1, background: 'var(--surface2)', borderRadius: 8, padding: '10px 14px', textAlign: 'center' }}>
          <div style={{ fontSize: 22, fontWeight: 800, color: 'var(--accent2)' }}>{lot.available_slots}</div>
          <div style={{ fontSize: 11, color: 'var(--text3)', marginTop: 2 }}>Available</div>
        </div>
        <div style={{ flex: 1, background: 'var(--surface2)', borderRadius: 8, padding: '10px 14px', textAlign: 'center' }}>
          <div style={{ fontSize: 22, fontWeight: 800, color: 'var(--accent4)' }}>{lot.occupied_slots}</div>
          <div style={{ fontSize: 11, color: 'var(--text3)', marginTop: 2 }}>Occupied</div>
        </div>
        <div style={{ flex: 1, background: 'var(--surface2)', borderRadius: 8, padding: '10px 14px', textAlign: 'center' }}>
          <div style={{ fontSize: 22, fontWeight: 800 }}>{lot.total_slots}</div>
          <div style={{ fontSize: 11, color: 'var(--text3)', marginTop: 2 }}>Total</div>
        </div>
      </div>

      <div style={{ marginBottom: 16 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, color: 'var(--text3)', marginBottom: 5 }}>
          <span>Occupancy</span><span style={{ color }}>{pct}%</span>
        </div>
        <div className="progress-wrap">
          <div className="progress-bar" style={{ width: `${pct}%`, background: color }} />
        </div>
      </div>

      <div style={{ display: 'flex', gap: 8 }}>
        <Link to={`/lots/${lot.id}`} className="btn btn-ghost btn-sm" style={{ flex: 1, justifyContent: 'center' }}>
          View Details
        </Link>
        {isAdmin && (
          <button onClick={() => onDelete(lot.id)} className="btn btn-danger btn-sm">🗑</button>
        )}
      </div>
    </div>
  );
}

function CreateLotModal({ onClose, onCreated }) {
  const [form, setForm] = useState({
    name: '', location: '', total_slots: 50,
    slot_config: [
      { vehicle_type: 'car',   count: 20, floor: 1 },
      { vehicle_type: 'bike',  count: 20, floor: 2 },
      { vehicle_type: 'truck', count: 10, floor: 3 },
    ],
    pricing: [
      { vehicle_type: 'car',   rate_type: 'hourly', rate: 50 },
      { vehicle_type: 'bike',  rate_type: 'hourly', rate: 20 },
      { vehicle_type: 'truck', rate_type: 'hourly', rate: 100 },
    ],
  });
  const [loading, setLoading] = useState(false);
  const [error, setError]     = useState('');

  const submit = async (e) => {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      const res = await lotsAPI.create(form);
      onCreated(res.data);
    } catch (err) {
      setError(err.message || 'Failed to create lot');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" onClick={e => e.target === e.currentTarget && onClose()}>
      <div className="modal">
        <div className="modal-header">
          <span className="modal-title">Create Parking Lot</span>
          <button className="modal-close" onClick={onClose}>✕</button>
        </div>
        {error && <div className="alert alert-error">{error}</div>}
        <form onSubmit={submit}>
          <div className="form-group">
            <label className="form-label">Name</label>
            <input className="form-input" placeholder="Connaught Place Parking"
              value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} required />
          </div>
          <div className="form-group">
            <label className="form-label">Location</label>
            <input className="form-input" placeholder="New Delhi, India"
              value={form.location} onChange={e => setForm({ ...form, location: e.target.value })} required />
          </div>
          <div className="form-group">
            <label className="form-label">Total Slots</label>
            <input className="form-input" type="number" min="1"
              value={form.total_slots} onChange={e => setForm({ ...form, total_slots: parseInt(e.target.value) })} required />
          </div>
          <div style={{ display: 'flex', gap: 10, marginTop: 16 }}>
            <button type="button" className="btn btn-ghost btn-full" onClick={onClose}>Cancel</button>
            <button type="submit" className="btn btn-primary btn-full" disabled={loading}>
              {loading ? 'Creating...' : 'Create Lot'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default function LotsPage() {
  const { isAdmin } = useAuth();
  const [lots, setLots]         = useState([]);
  const [loading, setLoading]   = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [search, setSearch]     = useState('');

  const load = async () => {
    setLoading(true);
    try { const r = await lotsAPI.list(); setLots(r.data || []); }
    catch (e) { console.error(e); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this parking lot?')) return;
    try { await lotsAPI.delete(id); setLots(l => l.filter(x => x.id !== id)); }
    catch (e) { alert(e.message); }
  };

  const filtered = lots.filter(l =>
    l.name.toLowerCase().includes(search.toLowerCase()) ||
    l.location.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Parking Lots</h1>
          <p className="page-subtitle">{lots.length} lots across India</p>
        </div>
        {isAdmin() && (
          <button className="btn btn-primary" onClick={() => setShowModal(true)}>+ Add Lot</button>
        )}
      </div>

      <div style={{ marginBottom: 20 }}>
        <input className="form-input" placeholder="🔍  Search lots by name or location..."
          value={search} onChange={e => setSearch(e.target.value)}
          style={{ maxWidth: 400 }} />
      </div>

      {loading ? (
        <div className="loading-screen" style={{ height: '50vh' }}><div className="spinner" /></div>
      ) : filtered.length === 0 ? (
        <div className="empty-state card">
          <div className="empty-icon">🅿️</div>
          <div className="empty-text">No parking lots found</div>
        </div>
      ) : (
        <div className="three-col">
          {filtered.map(lot => (
            <LotCard key={lot.id} lot={lot} isAdmin={isAdmin()} onDelete={handleDelete} />
          ))}
        </div>
      )}

      {showModal && (
        <CreateLotModal
          onClose={() => setShowModal(false)}
          onCreated={(lot) => { setLots(prev => [...prev, lot]); setShowModal(false); }}
        />
      )}
    </div>
  );
}
