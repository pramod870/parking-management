// src/pages/BookingsPage.js
import React, { useState, useEffect } from 'react';
import { bookingsAPI, lotsAPI } from '../services/api';

function CreateBookingModal({ lots, onClose, onCreated }) {
  const [form, setForm] = useState({
    lot_id: '', vehicle_type: 'car', vehicle_number: '',
    start_time: '', end_time: '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError]     = useState('');

  const submit = async (e) => {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      const payload = { ...form, lot_id: parseInt(form.lot_id) };
      const res = await bookingsAPI.create(payload);
      onCreated(res.data);
    } catch (err) {
      setError(err.message || 'Booking failed');
    } finally {
      setLoading(false);
    }
  };

  // Default times — 1 hour from now
  const now   = new Date(); now.setMinutes(0, 0, 0); now.setHours(now.getHours() + 1);
  const then  = new Date(now); then.setHours(then.getHours() + 2);
  const fmt   = d => d.toISOString().slice(0, 16);

  return (
    <div className="modal-overlay" onClick={e => e.target === e.currentTarget && onClose()}>
      <div className="modal">
        <div className="modal-header">
          <span className="modal-title">Book a Parking Slot</span>
          <button className="modal-close" onClick={onClose}>✕</button>
        </div>
        {error && <div className="alert alert-error">{error}</div>}
        <form onSubmit={submit}>
          <div className="form-group">
            <label className="form-label">Parking Lot</label>
            <select className="form-select" value={form.lot_id} onChange={e => setForm({ ...form, lot_id: e.target.value })} required>
              <option value="">Select lot...</option>
              {lots.map(l => <option key={l.id} value={l.id}>{l.name} ({l.available_slots} available)</option>)}
            </select>
          </div>
          <div className="two-col">
            <div className="form-group">
              <label className="form-label">Vehicle Type</label>
              <select className="form-select" value={form.vehicle_type} onChange={e => setForm({ ...form, vehicle_type: e.target.value })}>
                <option value="car">Car</option>
                <option value="bike">Bike</option>
                <option value="truck">Truck</option>
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Vehicle Number</label>
              <input className="form-input mono" placeholder="DL01AB1234" style={{ textTransform: 'uppercase' }}
                value={form.vehicle_number} onChange={e => setForm({ ...form, vehicle_number: e.target.value.toUpperCase() })} />
            </div>
          </div>
          <div className="two-col">
            <div className="form-group">
              <label className="form-label">Start Time</label>
              <input className="form-input" type="datetime-local"
                defaultValue={fmt(now)}
                onChange={e => setForm({ ...form, start_time: e.target.value.replace('T', ' ') + ':00' })} required />
            </div>
            <div className="form-group">
              <label className="form-label">End Time</label>
              <input className="form-input" type="datetime-local"
                defaultValue={fmt(then)}
                onChange={e => setForm({ ...form, end_time: e.target.value.replace('T', ' ') + ':00' })} required />
            </div>
          </div>
          <div style={{ display: 'flex', gap: 10 }}>
            <button type="button" className="btn btn-ghost btn-full" onClick={onClose}>Cancel</button>
            <button type="submit" className="btn btn-primary btn-full" disabled={loading}>
              {loading ? 'Booking...' : 'Confirm Booking'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

const STATUS_BADGE = {
  confirmed: 'badge-green', pending: 'badge-yellow', cancelled: 'badge-red',
  expired: 'badge-gray', active: 'badge-blue', completed: 'badge-purple',
};

export default function BookingsPage() {
  const [bookings, setBookings] = useState([]);
  const [lots, setLots]         = useState([]);
  const [loading, setLoading]   = useState(true);
  const [showModal, setShowModal] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const [bRes, lRes] = await Promise.all([bookingsAPI.list(), lotsAPI.list()]);
      setBookings(bRes.data || []);
      setLots(lRes.data || []);
    } catch (e) { console.error(e); }
    finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const handleCancel = async (id) => {
    if (!window.confirm('Cancel this booking?')) return;
    try {
      await bookingsAPI.cancel(id);
      setBookings(prev => prev.map(b => b.id === id ? { ...b, status: 'cancelled' } : b));
    } catch (err) { alert(err.message); }
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">My Bookings</h1>
          <p className="page-subtitle">{bookings.length} bookings total</p>
        </div>
        <button className="btn btn-primary" onClick={() => setShowModal(true)}>+ New Booking</button>
      </div>

      <div className="card">
        {loading ? (
          <div className="loading-screen" style={{ height: '40vh' }}><div className="spinner" /></div>
        ) : bookings.length === 0 ? (
          <div className="empty-state">
            <div className="empty-icon">📅</div>
            <div className="empty-text">No bookings yet</div>
            <div className="empty-sub">Pre-book your parking slot in advance</div>
            <button className="btn btn-primary" style={{ marginTop: 16 }} onClick={() => setShowModal(true)}>Create First Booking</button>
          </div>
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr><th>Reference</th><th>Lot</th><th>Vehicle</th><th>Type</th><th>Start</th><th>End</th><th>Fee</th><th>Status</th><th>Action</th></tr>
              </thead>
              <tbody>
                {bookings.map(b => (
                  <tr key={b.id}>
                    <td><span className="mono badge badge-gray">{b.booking_reference}</span></td>
                    <td>{b.parking_lot}</td>
                    <td><span className="mono">{b.vehicle_number || '—'}</span></td>
                    <td><span className="badge badge-blue">{b.vehicle_type}</span></td>
                    <td style={{ fontSize: 13, color: 'var(--text2)' }}>
                      {new Date(b.start_time).toLocaleString('en-IN', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })}
                    </td>
                    <td style={{ fontSize: 13, color: 'var(--text2)' }}>
                      {new Date(b.end_time).toLocaleString('en-IN', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })}
                    </td>
                    <td>{b.estimated_fee ? `₹${parseFloat(b.estimated_fee).toFixed(0)}` : '—'}</td>
                    <td><span className={`badge ${STATUS_BADGE[b.status] || 'badge-gray'}`}>{b.status}</span></td>
                    <td>
                      {['confirmed', 'pending'].includes(b.status) && (
                        <button onClick={() => handleCancel(b.id)} className="btn btn-danger btn-sm">Cancel</button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {showModal && (
        <CreateBookingModal
          lots={lots}
          onClose={() => setShowModal(false)}
          onCreated={(b) => { setBookings(prev => [b, ...prev]); setShowModal(false); }}
        />
      )}
    </div>
  );
}
