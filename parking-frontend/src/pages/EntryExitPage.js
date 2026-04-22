// src/pages/EntryExitPage.js
import React, { useState, useEffect } from 'react';
import { sessionsAPI, lotsAPI } from '../services/api';

function EntryForm({ lots }) {
  const [form, setForm]       = useState({ lot_id: '', vehicle_number: '', vehicle_type: 'car' });
  const [loading, setLoading] = useState(false);
  const [result, setResult]   = useState(null);
  const [error, setError]     = useState('');

  const submit = async (e) => {
    e.preventDefault();
    setError(''); setResult(null); setLoading(true);
    try {
      const res = await sessionsAPI.entry({ ...form, lot_id: parseInt(form.lot_id) });
      setResult(res.data);
      setForm({ lot_id: '', vehicle_number: '', vehicle_type: 'car' });
    } catch (err) {
      setError(err.message || 'Entry failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="card">
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20 }}>
        <div style={{ width: 36, height: 36, background: 'rgba(16,185,129,.15)', borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18 }}>⬆</div>
        <div>
          <div style={{ fontWeight: 700, fontSize: 16 }}>Vehicle Entry</div>
          <div style={{ fontSize: 12, color: 'var(--text3)' }}>Register incoming vehicle</div>
        </div>
      </div>

      {error  && <div className="alert alert-error">{error}</div>}
      {result && (
        <div className="alert alert-success" style={{ marginBottom: 16 }}>
          <div style={{ fontWeight: 700, marginBottom: 6 }}>✅ Entry Registered!</div>
          <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 13 }}>
            <div>🎫 Slot: <strong>{result.slot_number}</strong> (Floor {result.floor})</div>
            <div>🕒 Entry: {result.entry_time}</div>
            <div>🚗 Type: {result.vehicle_type}</div>
            <div style={{ fontSize: 11, color: 'var(--text2)', marginTop: 6 }}>Lot: {result.parking_lot}</div>
          </div>
        </div>
      )}

      <form onSubmit={submit}>
        <div className="form-group">
          <label className="form-label">Parking Lot</label>
          <select className="form-select" value={form.lot_id} onChange={e => setForm({ ...form, lot_id: e.target.value })} required>
            <option value="">Select lot...</option>
            {lots.map(l => (
              <option key={l.id} value={l.id}>{l.name} ({l.available_slots} available)</option>
            ))}
          </select>
        </div>
        <div className="form-group">
          <label className="form-label">Vehicle Number</label>
          <input className="form-input mono" placeholder="DL01AB1234"
            style={{ textTransform: 'uppercase' }}
            value={form.vehicle_number} onChange={e => setForm({ ...form, vehicle_number: e.target.value.toUpperCase() })} required />
        </div>
        <div className="form-group">
          <label className="form-label">Vehicle Type</label>
          <select className="form-select" value={form.vehicle_type} onChange={e => setForm({ ...form, vehicle_type: e.target.value })}>
            <option value="car">🚗 Car / SUV</option>
            <option value="bike">🏍 Bike / Scooter</option>
            <option value="truck">🚛 Truck / Bus</option>
          </select>
        </div>
        <button type="submit" className="btn btn-success btn-full btn-lg" disabled={loading}>
          {loading ? 'Registering...' : '⬆ Register Entry'}
        </button>
      </form>
    </div>
  );
}

function ExitForm() {
  const [ticketId, setTicketId] = useState('');
  const [payMethod, setPayMethod] = useState('cash');
  const [loading, setLoading]   = useState(false);
  const [stage, setStage]       = useState('exit'); // 'exit' | 'receipt'
  const [exitData, setExitData] = useState(null);
  const [receipt, setReceipt]   = useState(null);
  const [error, setError]       = useState('');

  const handleExit = async (e) => {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      const res = await sessionsAPI.exit(parseInt(ticketId), payMethod);
      setExitData(res.data);
      setStage('receipt');
    } catch (err) {
      setError(err.message || 'Exit failed');
    } finally {
      setLoading(false);
    }
  };

  const handlePay = async () => {
    setLoading(true);
    try {
      const txId = 'TXN' + Math.random().toString(36).substring(2, 12).toUpperCase();
      const res  = await sessionsAPI.pay(parseInt(ticketId), txId);
      setReceipt(res.invoice);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const reset = () => { setTicketId(''); setStage('exit'); setExitData(null); setReceipt(null); setError(''); };

  return (
    <div className="card">
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20 }}>
        <div style={{ width: 36, height: 36, background: 'rgba(239,68,68,.15)', borderRadius: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18 }}>⬇</div>
        <div>
          <div style={{ fontWeight: 700, fontSize: 16 }}>Vehicle Exit</div>
          <div style={{ fontSize: 12, color: 'var(--text3)' }}>Process exit & payment</div>
        </div>
      </div>

      {error && <div className="alert alert-error">{error}</div>}

      {stage === 'exit' && (
        <form onSubmit={handleExit}>
          <div className="form-group">
            <label className="form-label">Session ID</label>
            <input className="form-input mono" type="number" placeholder="Session ID from entry"
              value={ticketId} onChange={e => setTicketId(e.target.value)} required />
            <div className="form-error" style={{ color: 'var(--text3)' }}>Enter the session ID shown at entry</div>
          </div>
          <div className="form-group">
            <label className="form-label">Payment Method</label>
            <select className="form-select" value={payMethod} onChange={e => setPayMethod(e.target.value)}>
              <option value="cash">💵 Cash</option>
              <option value="card">💳 Card</option>
              <option value="upi">📱 UPI</option>
              <option value="online">🌐 Online</option>
            </select>
          </div>
          <button type="submit" className="btn btn-danger btn-full btn-lg" disabled={loading}>
            {loading ? 'Processing...' : '⬇ Process Exit'}
          </button>
        </form>
      )}

      {stage === 'receipt' && exitData && !receipt && (
        <div>
          <div style={{ background: 'var(--surface2)', borderRadius: 10, padding: 16, marginBottom: 16 }}>
            <div style={{ fontWeight: 700, marginBottom: 12, fontSize: 15 }}>Exit Summary</div>
            <div style={{ fontFamily: 'JetBrains Mono, monospace', fontSize: 13, display: 'flex', flexDirection: 'column', gap: 6 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}><span style={{ color: 'var(--text3)' }}>Vehicle</span><span>{exitData.vehicle_number}</span></div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}><span style={{ color: 'var(--text3)' }}>Entry</span><span>{exitData.entry_time}</span></div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}><span style={{ color: 'var(--text3)' }}>Exit</span><span>{exitData.exit_time}</span></div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}><span style={{ color: 'var(--text3)' }}>Duration</span><span>{exitData.duration_readable}</span></div>
              <hr style={{ border: 'none', borderTop: '1px solid var(--border)', margin: '6px 0' }} />
              <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 700, fontSize: 18 }}>
                <span>Total Fee</span>
                <span style={{ color: 'var(--accent2)' }}>₹{parseFloat(exitData.total_fee || 0).toFixed(2)}</span>
              </div>
            </div>
          </div>
          <button onClick={handlePay} className="btn btn-success btn-full btn-lg" disabled={loading}>
            {loading ? 'Processing...' : '✅ Confirm Payment'}
          </button>
        </div>
      )}

      {receipt && (
        <div>
          <div style={{ textAlign: 'center', padding: '16px 0 12px' }}>
            <div style={{ fontSize: 36 }}>🧾</div>
            <div style={{ fontWeight: 800, fontSize: 18, color: 'var(--accent2)', marginTop: 8 }}>Payment Confirmed!</div>
          </div>
          <div style={{ background: 'var(--surface2)', borderRadius: 10, padding: 16, fontFamily: 'JetBrains Mono, monospace', fontSize: 12, marginBottom: 16 }}>
            <div style={{ textAlign: 'center', fontWeight: 700, marginBottom: 10, letterSpacing: 2 }}>RECEIPT</div>
            {[
              ['Invoice', receipt.invoice_no],
              ['Vehicle', receipt.vehicle_number],
              ['Lot', receipt.parking_lot],
              ['Slot', receipt.slot_number],
              ['Entry', receipt.entry_time],
              ['Exit', receipt.exit_time],
              ['Duration', `${receipt.duration_minutes} min`],
              ['Payment', receipt.payment_method?.toUpperCase()],
              ['TXN ID', receipt.transaction_id],
            ].map(([k, v]) => v && (
              <div key={k} style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 5 }}>
                <span style={{ color: 'var(--text3)' }}>{k}</span><span>{v}</span>
              </div>
            ))}
            <hr style={{ border: 'none', borderTop: '1px dashed var(--border)', margin: '8px 0' }} />
            <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 700, fontSize: 16 }}>
              <span>TOTAL</span>
              <span style={{ color: 'var(--accent2)' }}>₹{parseFloat(receipt.total_fee).toFixed(2)}</span>
            </div>
          </div>
          <button onClick={reset} className="btn btn-ghost btn-full">Process Another Vehicle</button>
        </div>
      )}
    </div>
  );
}

export default function EntryExitPage() {
  const [lots, setLots] = useState([]);

  useEffect(() => {
    lotsAPI.list().then(r => setLots(r.data || [])).catch(console.error);
  }, []);

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Entry / Exit</h1>
          <p className="page-subtitle">Register vehicle movements and process payments</p>
        </div>
      </div>
      <div className="two-col">
        <EntryForm lots={lots} />
        <ExitForm />
      </div>
    </div>
  );
}
