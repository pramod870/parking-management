// src/pages/ProfilePage.js
import React, { useState } from 'react';
import { authAPI } from '../services/api';
import { useAuth } from '../context/AuthContext';

export default function ProfilePage() {
  const { user } = useAuth();
  const [form, setForm]     = useState({ name: user?.name || '', phone: '', password: '' });
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError]     = useState('');

  const submit = async (e) => {
    e.preventDefault();
    setError(''); setSuccess(''); setLoading(true);
    const payload = {};
    if (form.name     && form.name !== user?.name) payload.name = form.name;
    if (form.phone)    payload.phone    = form.phone;
    if (form.password) payload.password = form.password;

    if (Object.keys(payload).length === 0) {
      setError('No changes to save');
      setLoading(false);
      return;
    }

    try {
      await authAPI.updateProfile(payload);
      setSuccess('Profile updated successfully!');
      setForm(f => ({ ...f, password: '' }));
    } catch (err) {
      setError(err.message || 'Update failed');
    } finally {
      setLoading(false);
    }
  };

  const roleLabel = user?.roles?.includes('ROLE_ADMIN') ? 'Administrator'
    : user?.roles?.includes('ROLE_OPERATOR') ? 'Operator' : 'User';
  const roleBadge = user?.roles?.includes('ROLE_ADMIN') ? 'badge-red'
    : user?.roles?.includes('ROLE_OPERATOR') ? 'badge-yellow' : 'badge-blue';

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">My Profile</h1>
          <p className="page-subtitle">Manage your account details</p>
        </div>
      </div>

      <div className="two-col" style={{ alignItems: 'start' }}>
        {/* Avatar card */}
        <div className="card" style={{ textAlign: 'center' }}>
          <div style={{
            width: 80, height: 80, background: 'var(--surface3)', borderRadius: '50%',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 32, fontWeight: 800, color: 'var(--accent)',
            border: '3px solid var(--border)', margin: '0 auto 16px',
          }}>
            {user?.name?.[0]?.toUpperCase() || 'U'}
          </div>
          <div style={{ fontWeight: 700, fontSize: 20, marginBottom: 6 }}>{user?.name}</div>
          <div style={{ color: 'var(--text2)', fontSize: 14, marginBottom: 12 }}>{user?.email}</div>
          <span className={`badge ${roleBadge}`} style={{ fontSize: 13, padding: '5px 14px' }}>{roleLabel}</span>

          <hr className="divider" />

          <div style={{ display: 'flex', flexDirection: 'column', gap: 8, fontSize: 13 }}>
            {[
              ['User ID', `#${user?.id}`],
              ['Email',   user?.email],
              ['Roles',   user?.roles?.join(', ')],
            ].map(([k, v]) => (
              <div key={k} style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--text2)' }}>
                <span>{k}</span>
                <span className="mono" style={{ color: 'var(--text)' }}>{v}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Edit form */}
        <div className="card">
          <div style={{ fontWeight: 700, fontSize: 16, marginBottom: 20 }}>Update Details</div>

          {error   && <div className="alert alert-error">{error}</div>}
          {success && <div className="alert alert-success">✅ {success}</div>}

          <form onSubmit={submit}>
            <div className="form-group">
              <label className="form-label">Full Name</label>
              <input className="form-input" value={form.name}
                onChange={e => setForm({ ...form, name: e.target.value })} />
            </div>
            <div className="form-group">
              <label className="form-label">Phone Number</label>
              <input className="form-input" type="tel" placeholder="9876543210"
                value={form.phone} onChange={e => setForm({ ...form, phone: e.target.value })} />
            </div>
            <hr className="divider" />
            <div style={{ fontWeight: 600, marginBottom: 12, fontSize: 14 }}>Change Password</div>
            <div className="form-group">
              <label className="form-label">New Password</label>
              <input className="form-input" type="password" placeholder="Leave blank to keep current"
                value={form.password} onChange={e => setForm({ ...form, password: e.target.value })} />
            </div>
            <button type="submit" className="btn btn-primary btn-full" disabled={loading}>
              {loading ? 'Saving...' : 'Save Changes'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
