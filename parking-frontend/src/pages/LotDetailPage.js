// src/pages/LotDetailPage.js
import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { lotsAPI } from '../services/api';

export default function LotDetailPage() {
  const { id } = useParams();
  const [lot, setLot]       = useState(null);
  const [slots, setSlots]   = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    const load = async () => {
      try {
        const [lotRes, slotRes] = await Promise.all([lotsAPI.get(id), lotsAPI.slots(id)]);
        setLot(lotRes.data);
        setSlots(slotRes.data || []);
      } catch (e) { console.error(e); }
      finally { setLoading(false); }
    };
    load();
  }, [id]);

  if (loading) return <div className="loading-screen" style={{ height: '60vh' }}><div className="spinner" /></div>;
  if (!lot)    return <div className="card"><p>Lot not found.</p></div>;

  const slotsByFloor = slots.reduce((acc, s) => {
    const f = s.floor || 1;
    if (!acc[f]) acc[f] = [];
    acc[f].push(s);
    return acc;
  }, {});

  const filterSlots = (arr) => filter === 'all' ? arr : arr.filter(s => s.status === filter);

  const pct = lot.total_slots > 0
    ? Math.round((lot.total_slots - lot.available_slots) / lot.total_slots * 100) : 0;

  return (
    <div>
      <div className="page-header">
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 4 }}>
            <Link to="/lots" style={{ color: 'var(--text3)', textDecoration: 'none', fontSize: 13 }}>← Lots</Link>
          </div>
          <h1 className="page-title">{lot.name}</h1>
          <p className="page-subtitle">📍 {lot.location}</p>
        </div>
        <span className={`badge ${lot.is_active ? 'badge-green' : 'badge-red'}`} style={{ fontSize: 13, padding: '6px 14px' }}>
          {lot.is_active ? '● Active' : '○ Inactive'}
        </span>
      </div>

      {/* Stats */}
      <div className="stats-grid" style={{ marginBottom: 24 }}>
        <div className="stat-card green">
          <div className="stat-label">Available</div>
          <div className="stat-value">{lot.available_slots}</div>
        </div>
        <div className="stat-card red">
          <div className="stat-label">Occupied</div>
          <div className="stat-value">{lot.occupied_slots}</div>
        </div>
        <div className="stat-card blue">
          <div className="stat-label">Total</div>
          <div className="stat-value">{lot.total_slots}</div>
        </div>
        <div className="stat-card yellow">
          <div className="stat-label">Occupancy</div>
          <div className="stat-value">{pct}%</div>
        </div>
      </div>

      <div className="two-col">
        {/* Slot map */}
        <div className="card" style={{ gridColumn: '1 / -1' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16, flexWrap: 'wrap', gap: 10 }}>
            <div style={{ fontWeight: 700 }}>Slot Map</div>
            <div style={{ display: 'flex', gap: 8 }}>
              {['all', 'available', 'occupied', 'reserved'].map(f => (
                <button key={f} onClick={() => setFilter(f)}
                  className={`btn btn-sm ${filter === f ? 'btn-primary' : 'btn-ghost'}`}
                  style={{ textTransform: 'capitalize' }}>
                  {f}
                </button>
              ))}
            </div>
          </div>

          {Object.entries(slotsByFloor).map(([floor, floorSlots]) => (
            <div key={floor} style={{ marginBottom: 20 }}>
              <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--text3)', letterSpacing: 1, textTransform: 'uppercase', marginBottom: 10 }}>
                Floor {floor}
              </div>
              <div className="slot-grid">
                {filterSlots(floorSlots).map(slot => (
                  <div key={slot.id} className={`slot-cell ${slot.status}`} title={`${slot.slot_number} — ${slot.status} (${slot.vehicle_type})`}>
                    <div style={{ fontWeight: 700 }}>{slot.slot_number}</div>
                    <div style={{ fontSize: 10, marginTop: 2, opacity: .8 }}>{slot.vehicle_type[0].toUpperCase()}</div>
                  </div>
                ))}
              </div>
            </div>
          ))}

          <div style={{ display: 'flex', gap: 16, marginTop: 12, fontSize: 12, color: 'var(--text2)' }}>
            <span><span style={{ color: 'var(--accent2)' }}>■</span> Available</span>
            <span><span style={{ color: 'var(--accent4)' }}>■</span> Occupied</span>
            <span><span style={{ color: 'var(--accent3)' }}>■</span> Reserved</span>
            <span style={{ marginLeft: 8, fontStyle: 'italic' }}>C=Car, B=Bike, T=Truck</span>
          </div>
        </div>

        {/* Pricing rules */}
        {lot.pricing_rules?.length > 0 && (
          <div className="card">
            <div style={{ fontWeight: 700, marginBottom: 16 }}>Pricing Rules</div>
            {lot.pricing_rules.map((r, i) => (
              <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 0', borderBottom: '1px solid var(--border)' }}>
                <div>
                  <div style={{ fontWeight: 600, textTransform: 'capitalize' }}>{r.vehicle_type}</div>
                  <div style={{ fontSize: 12, color: 'var(--text3)' }}>
                    {r.free_minutes > 0 && `${r.free_minutes} min free`}
                    {r.minimum_charge && ` · Min ₹${r.minimum_charge}`}
                  </div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  {r.rate_type === 'flat' ? (
                    <span className="badge badge-purple">Flat ₹{r.rate}</span>
                  ) : (
                    <span className="badge badge-green">₹{r.rate}/{r.rate_type === 'hourly' ? 'hr' : 'min'}</span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
